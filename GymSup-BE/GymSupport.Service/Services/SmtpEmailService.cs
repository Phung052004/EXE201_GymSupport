using GymSupport.Service.Interfaces;
using Microsoft.Extensions.Configuration;
using System;
using System.IO;
using System.Net;
using System.Net.Mail;
using System.Threading.Tasks;

namespace GymSupport.Service.Services
{
    public class SmtpEmailService : IEmailService
    {
        private readonly IConfiguration _config;
        private const string EmailTemplatePath = "Templates/EmailVerificationTemplate.html";
        private const string ReceiptTemplatePath = "Templates/PaymentReceiptTemplate.html";

        public SmtpEmailService(IConfiguration config)
        {
            _config = config;
        }

        public async Task SendEmailVerificationAsync(string email, string verificationUrl)
        {
            var body = await BuildEmailBodyAsync(verificationUrl);
            await SendAsync(email, "Xác thực email của bạn", body);
        }

        public async Task SendPaymentReceiptAsync(string email, PaymentReceiptEmailDto receipt)
        {
            var body = await BuildReceiptBodyAsync(receipt);
            await SendAsync(email, $"Biên nhận thanh toán GymSupport #{receipt.ReceiptNumber}", body);
        }

        private async Task SendAsync(string toEmail, string subject, string htmlBody)
        {
            var smtpHost = _config["Smtp:Host"];
            if (string.IsNullOrWhiteSpace(smtpHost))
            {
                Console.WriteLine("[Email] SMTP is not configured. Would have sent:");
                Console.WriteLine($"To: {toEmail}");
                Console.WriteLine($"Subject: {subject}");
                return;
            }

            var smtpPort = int.TryParse(_config["Smtp:Port"], out var port) ? port : 25;
            var enableSsl = bool.TryParse(_config["Smtp:EnableSsl"], out var ssl) && ssl;
            var fromAddress = _config["Smtp:From"] ?? _config["Smtp:Username"] ?? "no-reply@example.com";

            var smtpUser = _config["Smtp:Username"];
            var smtpPass = _config["Smtp:Password"];

            using var message = new MailMessage(fromAddress, toEmail, subject, htmlBody)
            {
                IsBodyHtml = true
            };
            using var client = new SmtpClient(smtpHost, smtpPort)
            {
                EnableSsl = enableSsl
            };

            if (!string.IsNullOrWhiteSpace(smtpUser))
            {
                client.Credentials = new NetworkCredential(smtpUser, smtpPass);
            }

            await client.SendMailAsync(message);
        }

        private async Task<string> BuildEmailBodyAsync(string verificationUrl)
        {
            var template = await ReadTemplateAsync(EmailTemplatePath);
            if (template != null)
            {
                return template.Replace("{{VERIFICATION_URL}}", verificationUrl, StringComparison.Ordinal);
            }

            return $"<html><body><p>Chào mừng bạn! Vui lòng xác thực email của bạn bằng cách nhấp vào liên kết bên dưới:</p><p><a href='{verificationUrl}'>Xác thực</a></p><p>Liên kết này có hiệu lực trong 10 phút.</p></body></html>";
        }

        private async Task<string> BuildReceiptBodyAsync(PaymentReceiptEmailDto receipt)
        {
            var template = await ReadTemplateAsync(ReceiptTemplatePath);
            if (template != null)
            {
                return template
                    .Replace("{{RECEIPT_NUMBER}}", receipt.ReceiptNumber, StringComparison.Ordinal)
                    .Replace("{{CUSTOMER_NAME}}", receipt.CustomerName, StringComparison.Ordinal)
                    .Replace("{{PLAN_NAME}}", receipt.PlanName, StringComparison.Ordinal)
                    .Replace("{{AMOUNT}}", receipt.AmountFormatted, StringComparison.Ordinal)
                    .Replace("{{PAYMENT_METHOD}}", receipt.PaymentMethod, StringComparison.Ordinal)
                    .Replace("{{ORDER_ID}}", receipt.OrderId, StringComparison.Ordinal)
                    .Replace("{{TRANSACTION_ID}}", string.IsNullOrWhiteSpace(receipt.TransactionId) ? "—" : receipt.TransactionId, StringComparison.Ordinal)
                    .Replace("{{PAID_AT}}", receipt.PaidAtFormatted, StringComparison.Ordinal);
            }

            return $"<html><body><p>Thanh toán #{receipt.ReceiptNumber} thành công: {receipt.AmountFormatted} cho gói {receipt.PlanName}.</p></body></html>";
        }

        private static async Task<string?> ReadTemplateAsync(string relativePath)
        {
            var templateFile = Path.Combine(AppContext.BaseDirectory, relativePath.Replace('/', Path.DirectorySeparatorChar));
            if (File.Exists(templateFile))
            {
                return await File.ReadAllTextAsync(templateFile);
            }

            return null;
        }
    }
}
