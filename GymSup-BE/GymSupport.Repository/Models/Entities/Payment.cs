using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace GymSupport.Repository.Models.Entities;

public class Payment
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = string.Empty;

    public string UserId { get; set; } = string.Empty;
    public string? CustomerId { get; set; }

    public string PaymentType { get; set; } = "Subscription";
    // Subscription, Other

    public string PlanName { get; set; } = string.Empty;

    public decimal Amount { get; set; }

    public string PaymentMethod { get; set; } = string.Empty;
    // VNPAY, MOMO, PAYOS, Cash, etc.

    public string Status { get; set; } = "Pending";
    // Pending, Paid, Failed, Cancelled, Refunded

    public DateTime PaidAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
