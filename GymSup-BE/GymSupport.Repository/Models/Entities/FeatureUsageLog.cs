using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace GymSupport.Repository.Models.Entities;

/// <summary>
/// Ghi nhận mỗi lần user gọi một tính năng AI Premium (phân tích ảnh/video, tạo lịch tập bằng AI).
/// Dùng để thống kê tần suất sử dụng thực tế cho báo cáo Outcome (Feature Usage / Premium Usage).
/// </summary>
[BsonIgnoreExtraElements]
public class FeatureUsageLog
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = string.Empty;

    public string UserId { get; set; } = string.Empty;

    /// <summary>EquipmentInfo, BodyCheck, FormCheckVideo, GenerateWorkoutPlan</summary>
    public string Feature { get; set; } = string.Empty;

    /// <summary>User có đang Premium tại thời điểm gọi tính năng hay không.</summary>
    public bool IsPremiumUser { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
