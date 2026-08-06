using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace GymSupport.Repository.Models.Entities;

/// <summary>
/// Biên nhận (receipt) được lưu lại mỗi khi một Payment chuyển sang trạng thái "Paid".
/// Đây là bằng chứng giao dịch cần cho báo cáo Outcome 3 (transaction receipts) —
/// lưu snapshot thông tin định danh khách hàng tại thời điểm thanh toán (email/tên có
/// thể đổi sau này nên không dựa hoàn toàn vào bản ghi User hiện tại).
/// </summary>
[BsonIgnoreExtraElements]
public class Receipt
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = string.Empty;

    /// <summary>Số biên nhận hiển thị cho người dùng, vd GS-20260806-00001.</summary>
    public string ReceiptNumber { get; set; } = string.Empty;

    public string PaymentId { get; set; } = string.Empty;
    public string UserId { get; set; } = string.Empty;

    // Snapshot định danh khách hàng tại thời điểm thanh toán.
    public string CustomerEmail { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;

    public string PlanName { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "VND";
    public string PaymentMethod { get; set; } = "PayOS";
    public string OrderId { get; set; } = string.Empty;
    public string? TransactionId { get; set; }
    public DateTime PaidAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>Pending, Sent, Failed</summary>
    public string EmailStatus { get; set; } = "Pending";
    public DateTime? EmailSentAt { get; set; }
    public string? EmailError { get; set; }
}
