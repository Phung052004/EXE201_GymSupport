using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.Entities;
using GymSupport.Service.Interfaces;

namespace GymSupport.API.Services;

public interface IPayOsService
{
    Task<PayOsCheckoutResult> CreateCheckoutAsync(string userId, string planId);
    Task<PayOsStatusResult> GetStatusAsync(string userId, string orderCode);
    Task HandleWebhookAsync(PayOsWebhookRequest payload);
}

public sealed class PayOsService : IPayOsService
{
    private const string ApiBaseUrl = "https://api-merchant.payos.vn";

    private readonly IConfiguration _configuration;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IPaymentRepository _payments;
    private readonly ISubscriptionPlanRepository _plans;
    private readonly ISubscriptionService _subscriptions;
    private readonly IUserRepository _users;
    private readonly IReceiptRepository _receipts;
    private readonly IEmailService _emailService;
    private readonly ILogger<PayOsService> _logger;

    public PayOsService(
        IConfiguration configuration,
        IHttpClientFactory httpClientFactory,
        IPaymentRepository payments,
        ISubscriptionPlanRepository plans,
        ISubscriptionService subscriptions,
        IUserRepository users,
        IReceiptRepository receipts,
        IEmailService emailService,
        ILogger<PayOsService> logger)
    {
        _configuration = configuration;
        _httpClientFactory = httpClientFactory;
        _payments = payments;
        _plans = plans;
        _subscriptions = subscriptions;
        _users = users;
        _receipts = receipts;
        _emailService = emailService;
        _logger = logger;
    }

    public async Task<PayOsCheckoutResult> CreateCheckoutAsync(string userId, string planId)
    {
        var plan = await _plans.GetByIdAsync(planId);
        if (plan is null || !plan.IsActive)
            throw new InvalidOperationException("Gói đăng ký không tồn tại hoặc đã ngưng hoạt động.");

        var settings = GetSettings();
        if (string.IsNullOrWhiteSpace(settings.ClientId) ||
            string.IsNullOrWhiteSpace(settings.ApiKey) ||
            string.IsNullOrWhiteSpace(settings.ChecksumKey))
        {
            throw new InvalidOperationException("Chưa cấu hình PayOS (ClientId/ApiKey/ChecksumKey).");
        }

        var amount = (int)Math.Round(plan.Price, MidpointRounding.AwayFromZero);
        // PayOS giới hạn độ dài description (~25 ký tự) — kiểm tra lại giới hạn thực tế trước khi go-live.
        var description = Truncate($"GS {plan.Name}", 25);

        Payment? payment = null;
        long orderCode = 0;
        for (var attempt = 0; attempt < 5 && payment is null; attempt++)
        {
            orderCode = GenerateOrderCode();
            var candidate = new Payment
            {
                UserId = userId,
                PlanId = plan.Id,
                PlanName = plan.Name,
                Amount = plan.Price,
                PaymentMethod = "PayOS",
                PaymentType = "Subscription",
                Status = "Pending",
                OrderId = orderCode.ToString(),
                RequestId = Guid.NewGuid().ToString("N"),
                CreatedAt = DateTime.UtcNow
            };
            try
            {
                await _payments.CreateAsync(candidate);
                payment = candidate;
            }
            catch (Exception)
            {
                // orderCode trùng (cực hiếm) — thử lại với orderCode khác.
            }
        }
        if (payment is null)
            throw new InvalidOperationException("Không tạo được đơn hàng PayOS, vui lòng thử lại.");

        var signature = BuildCheckoutSignature(
            orderCode, amount, description, settings.CancelUrl, settings.ReturnUrl, settings.ChecksumKey);

        var requestBody = new Dictionary<string, object?>
        {
            ["orderCode"] = orderCode,
            ["amount"] = amount,
            ["description"] = description,
            ["returnUrl"] = settings.ReturnUrl,
            ["cancelUrl"] = settings.CancelUrl,
            ["signature"] = signature
        };

        var client = _httpClientFactory.CreateClient();
        using var request = new HttpRequestMessage(HttpMethod.Post, $"{ApiBaseUrl}/v2/payment-requests")
        {
            Content = new StringContent(JsonSerializer.Serialize(requestBody), Encoding.UTF8, "application/json")
        };
        request.Headers.Add("x-client-id", settings.ClientId);
        request.Headers.Add("x-api-key", settings.ApiKey);

        using var response = await client.SendAsync(request);
        var body = await response.Content.ReadAsStringAsync();
        if (!response.IsSuccessStatusCode)
            throw new InvalidOperationException($"PayOS từ chối tạo link thanh toán: {body}");

        using var document = JsonDocument.Parse(body);
        var data = document.RootElement.GetProperty("data");

        return new PayOsCheckoutResult(
            orderCode.ToString(),
            GetString(data, "checkoutUrl"),
            GetString(data, "qrCode"),
            plan.Price,
            plan.Name,
            GetString(data, "status"));
    }

    public async Task<PayOsStatusResult> GetStatusAsync(string userId, string orderCode)
    {
        var payment = await _payments.GetByOrderIdAsync(orderCode)
            ?? throw new KeyNotFoundException("Không tìm thấy đơn hàng.");
        if (payment.UserId != userId)
            throw new UnauthorizedAccessException("Đơn hàng không thuộc về tài khoản này.");

        if (IsTerminalStatus(payment.Status))
            return ToStatusResult(payment);

        // Poll trực tiếp PayOS như một cơ chế tự phục hồi phòng khi webhook bị trễ/mất —
        // webhook vẫn là nguồn xác nhận chính, đây chỉ là fallback.
        var settings = GetSettings();
        var client = _httpClientFactory.CreateClient();
        using var request = new HttpRequestMessage(HttpMethod.Get, $"{ApiBaseUrl}/v2/payment-requests/{orderCode}");
        request.Headers.Add("x-client-id", settings.ClientId);
        request.Headers.Add("x-api-key", settings.ApiKey);

        using var response = await client.SendAsync(request);
        if (!response.IsSuccessStatusCode)
            return ToStatusResult(payment);

        var body = await response.Content.ReadAsStringAsync();
        using var document = JsonDocument.Parse(body);
        var data = document.RootElement.GetProperty("data");
        var payOsStatus = GetString(data, "status");

        if (payOsStatus == "PAID" && payment.Status != "Paid")
        {
            string? reference = null;
            DateTime paidAt = DateTime.UtcNow;
            if (data.TryGetProperty("transactions", out var transactions) &&
                transactions.ValueKind == JsonValueKind.Array &&
                transactions.GetArrayLength() > 0)
            {
                var latestTx = transactions[0];
                reference = GetString(latestTx, "reference");
                if (DateTime.TryParse(GetString(latestTx, "transactionDateTime"), out var parsed))
                    paidAt = DateTime.SpecifyKind(parsed, DateTimeKind.Utc);
            }
            await ActivatePaidPaymentAsync(payment, reference, paidAt, "Xác nhận qua polling status");
        }
        else if (payOsStatus is "CANCELLED" or "EXPIRED" && payment.Status == "Pending")
        {
            payment.Status = "Cancelled";
            payment.UpdatedAt = DateTime.UtcNow;
            await _payments.UpdateAsync(payment);
        }

        return ToStatusResult(payment);
    }

    public async Task HandleWebhookAsync(PayOsWebhookRequest payload)
    {
        var settings = GetSettings();
        var expectedSignature = BuildWebhookDataSignature(payload.Data, settings.ChecksumKey);
        if (!string.Equals(expectedSignature, payload.Signature, StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("Chữ ký webhook PayOS không hợp lệ.");

        var orderCode = GetString(payload.Data, "orderCode");
        if (string.IsNullOrWhiteSpace(orderCode) && payload.Data.TryGetProperty("orderCode", out var codeEl))
            orderCode = codeEl.GetRawText();

        var payment = await _payments.GetByOrderIdAsync(orderCode);
        if (payment is null) return; // webhook lạ/trùng — trả 200 để PayOS ngưng retry.
        if (payment.Status == "Paid") return; // đã xử lý — idempotent no-op.

        var reference = GetString(payload.Data, "reference");
        var paidAt = DateTime.UtcNow;
        if (DateTime.TryParse(GetString(payload.Data, "transactionDateTime"), out var parsed))
            paidAt = DateTime.SpecifyKind(parsed, DateTimeKind.Utc);

        await ActivatePaidPaymentAsync(payment, reference, paidAt, payload.Desc);
    }

    private async Task ActivatePaidPaymentAsync(
        Payment payment, string? transactionId, DateTime paidAt, string? providerMessage)
    {
        var plan = await _plans.GetByIdAsync(payment.PlanId)
            ?? throw new InvalidOperationException($"Không tìm thấy gói {payment.PlanName}.");
        var expiresAt = DateTime.UtcNow.AddMonths(plan.DurationMonths);

        await _subscriptions.ActivateVerifiedSubscriptionAsync(payment.UserId, payment.PlanId, expiresAt);

        payment.Status = "Paid";
        payment.TransactionId = transactionId;
        payment.PaidAt = paidAt;
        payment.ProviderMessage = providerMessage;
        payment.UpdatedAt = DateTime.UtcNow;
        await _payments.UpdateAsync(payment);

        // Lưu receipt + gửi email — best-effort: lỗi ở đây không được làm hỏng việc kích hoạt
        // subscription đã thành công ở trên.
        await CreateAndSendReceiptAsync(payment, transactionId, paidAt);
    }

    private async Task CreateAndSendReceiptAsync(Payment payment, string? transactionId, DateTime paidAt)
    {
        Receipt? receipt = null;
        try
        {
            var existing = await _receipts.GetByPaymentIdAsync(payment.Id);
            if (existing != null) return; // idempotent — webhook/polling có thể gọi lại.

            var user = await _users.GetByIdAsync(payment.UserId);
            var receiptCount = await _receipts.CountAsync();

            receipt = new Receipt
            {
                ReceiptNumber = $"GS-{DateTime.UtcNow:yyyyMMdd}-{receiptCount + 1:D5}",
                PaymentId = payment.Id,
                UserId = payment.UserId,
                CustomerEmail = user?.Email ?? string.Empty,
                CustomerName = user?.FullName ?? string.Empty,
                PlanName = payment.PlanName,
                Amount = payment.Amount,
                Currency = "VND",
                PaymentMethod = payment.PaymentMethod,
                OrderId = payment.OrderId,
                TransactionId = transactionId,
                PaidAt = paidAt
            };
            await _receipts.CreateAsync(receipt);

            if (string.IsNullOrWhiteSpace(receipt.CustomerEmail))
            {
                _logger.LogWarning("Receipt {ReceiptNumber} không có email — bỏ qua gửi mail.", receipt.ReceiptNumber);
                return;
            }

            await _emailService.SendPaymentReceiptAsync(receipt.CustomerEmail, new PaymentReceiptEmailDto
            {
                ReceiptNumber = receipt.ReceiptNumber,
                CustomerName = string.IsNullOrWhiteSpace(receipt.CustomerName) ? "Quý khách" : receipt.CustomerName,
                PlanName = receipt.PlanName,
                AmountFormatted = $"{receipt.Amount:N0} {receipt.Currency}",
                PaymentMethod = receipt.PaymentMethod,
                OrderId = receipt.OrderId,
                TransactionId = receipt.TransactionId ?? string.Empty,
                PaidAtFormatted = receipt.PaidAt.ToString("dd/MM/yyyy HH:mm")
            });

            receipt.EmailStatus = "Sent";
            receipt.EmailSentAt = DateTime.UtcNow;
            await _receipts.UpdateAsync(receipt);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Không gửi được receipt email cho Payment {PaymentId}.", payment.Id);
            if (receipt != null)
            {
                receipt.EmailStatus = "Failed";
                receipt.EmailError = ex.Message;
                try { await _receipts.UpdateAsync(receipt); } catch { /* best-effort */ }
            }
        }
    }

    private static bool IsTerminalStatus(string status) =>
        status is "Paid" or "Cancelled" or "Failed" or "Refunded";

    private static PayOsStatusResult ToStatusResult(Payment payment) =>
        new(payment.OrderId, payment.Status, payment.Amount, payment.PaidAt);

    private PayOsSettings GetSettings() =>
        _configuration.GetSection("PayOs").Get<PayOsSettings>() ?? new();

    private static long GenerateOrderCode() =>
        DateTimeOffset.UtcNow.ToUnixTimeSeconds() * 1000 + Random.Shared.Next(0, 999);

    private static string BuildCheckoutSignature(
        long orderCode, int amount, string description, string cancelUrl, string returnUrl, string checksumKey)
    {
        var data = $"amount={amount}&cancelUrl={cancelUrl}&description={description}" +
                   $"&orderCode={orderCode}&returnUrl={returnUrl}";
        return HmacSha256Hex(data, checksumKey);
    }

    private static string BuildWebhookDataSignature(JsonElement data, string checksumKey)
    {
        var pairs = new List<(string Key, string Value)>();
        foreach (var prop in data.EnumerateObject())
        {
            var value = prop.Value.ValueKind switch
            {
                JsonValueKind.String => prop.Value.GetString() ?? string.Empty,
                JsonValueKind.Number => prop.Value.GetRawText(),
                JsonValueKind.True => "true",
                JsonValueKind.False => "false",
                JsonValueKind.Null => string.Empty,
                _ => prop.Value.GetRawText()
            };
            pairs.Add((prop.Name, value));
        }
        var sorted = pairs.OrderBy(p => p.Key, StringComparer.Ordinal);
        var joined = string.Join("&", sorted.Select(p => $"{p.Key}={p.Value}"));
        return HmacSha256Hex(joined, checksumKey);
    }

    private static string HmacSha256Hex(string data, string key)
    {
        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(key));
        var hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(data));
        return Convert.ToHexString(hash).ToLowerInvariant();
    }

    private static string Truncate(string value, int maxLength) =>
        value.Length <= maxLength ? value : value[..maxLength];

    private static string GetString(JsonElement element, string name) =>
        element.TryGetProperty(name, out var value)
            ? value.ValueKind == JsonValueKind.String ? value.GetString() ?? string.Empty : value.GetRawText()
            : string.Empty;
}

public sealed class PayOsSettings
{
    public string ClientId { get; set; } = string.Empty;
    public string ApiKey { get; set; } = string.Empty;
    public string ChecksumKey { get; set; } = string.Empty;
    public string ReturnUrl { get; set; } = string.Empty;
    public string CancelUrl { get; set; } = string.Empty;
}

public sealed class PayOsWebhookRequest
{
    public string? Code { get; set; }
    public string? Desc { get; set; }
    public bool Success { get; set; }
    public JsonElement Data { get; set; }
    public string Signature { get; set; } = string.Empty;
}

public sealed record PayOsCheckoutResult(
    string OrderCode,
    string CheckoutUrl,
    string QrCode,
    decimal Amount,
    string PlanName,
    string Status);

public sealed record PayOsStatusResult(
    string OrderCode,
    string Status,
    decimal Amount,
    DateTime? PaidAt);
