namespace GymSupport.Service.Interfaces;

public interface IAnalyticsService
{
    Task<ActiveUsersDto> GetActiveUsersAsync(DateTime from, DateTime to);
    Task<RetentionDto> GetRetentionAsync(DateTime from, DateTime to);
    Task<FunnelDto> GetFunnelAsync(string name);
    Task<FeatureUsageDto> GetFeatureUsageAsync(DateTime from, DateTime to);
    Task<WorkoutAnalyticsDto> GetWorkoutAnalyticsAsync(DateTime from, DateTime to);
    Task<List<PremiumUserUsageDto>> GetPremiumUsersUsageAsync();
    Task<List<FeatureUsageDetailDto>> GetFeatureUsageDetailAsync(string userId, string feature);
}

// ── Active Users ──────────────────────────────────────────────────────────────

public class ActiveUsersDto
{
    public string From { get; set; } = "";
    public string To { get; set; } = "";
    /// <summary>Average Daily Active Users over the period</summary>
    public double Dau { get; set; }
    /// <summary>Average Weekly Active Users over the period</summary>
    public double Wau { get; set; }
    /// <summary>Unique active users in the entire period (Monthly Active Users proxy)</summary>
    public int Mau { get; set; }
    public List<DailyActiveDto> DailyBreakdown { get; set; } = new();
}

public class DailyActiveDto
{
    public string Date { get; set; } = "";
    public int ActiveUsers { get; set; }
}

// ── Retention ─────────────────────────────────────────────────────────────────

public class RetentionDto
{
    public string From { get; set; } = "";
    public string To { get; set; } = "";
    /// <summary>Users who registered in the given period (cohort base)</summary>
    public int CohortSize { get; set; }
    public double Day1Retention { get; set; }
    public double Day7Retention { get; set; }
    public double Day30Retention { get; set; }
    public int Day1RetainedUsers { get; set; }
    public int Day7RetainedUsers { get; set; }
    public int Day30RetainedUsers { get; set; }
    /// <summary>Users eligible for Day7 check (registered at least 7 days ago)</summary>
    public int Day7EligibleUsers { get; set; }
    /// <summary>Users eligible for Day30 check (registered at least 30 days ago)</summary>
    public int Day30EligibleUsers { get; set; }
}

// ── Funnel ────────────────────────────────────────────────────────────────────

public class FunnelDto
{
    public string Name { get; set; } = "";
    public List<FunnelStepDto> Steps { get; set; } = new();
}

public class FunnelStepDto
{
    public string Step { get; set; } = "";
    public string Label { get; set; } = "";
    public int Count { get; set; }
    /// <summary>Conversion rate % from the previous step</summary>
    public double ConversionFromPrevious { get; set; }
    /// <summary>Conversion rate % from the first step</summary>
    public double ConversionFromStart { get; set; }
    /// <summary>Number of users dropped compared to previous step</summary>
    public int DroppedFromPrevious { get; set; }
}

// ── Feature Usage ─────────────────────────────────────────────────────────────

public class FeatureUsageDto
{
    public string From { get; set; } = "";
    public string To { get; set; } = "";
    public List<FeatureUsageItemDto> Features { get; set; } = new();
}

public class FeatureUsageItemDto
{
    public string Feature { get; set; } = "";
    public int UsageCount { get; set; }
    public int UniqueUsers { get; set; }
}

// ── Workout Analytics ─────────────────────────────────────────────────────────

public class WorkoutAnalyticsDto
{
    public string From { get; set; } = "";
    public string To { get; set; } = "";
    public int TotalSessionsStarted { get; set; }
    public int TotalSessionsCompleted { get; set; }
    public double CompletionRate { get; set; }
    /// <summary>Average duration of completed sessions in minutes</summary>
    public double AverageDurationMinutes { get; set; }
    public List<ExerciseUsageDto> MostPopularExercises { get; set; } = new();
    public List<MuscleUsageDto> MostTrainedMuscles { get; set; } = new();
    public List<ConsistentUserDto> MostConsistentUsers { get; set; } = new();
}

public class ExerciseUsageDto
{
    public string ExerciseName { get; set; } = "";
    public int Count { get; set; }
}

public class MuscleUsageDto
{
    public string MuscleName { get; set; } = "";
    public int TotalExpGained { get; set; }
    public int AppearanceCount { get; set; }
}

public class ConsistentUserDto
{
    public string UserId { get; set; } = "";
    public string UserName { get; set; } = "";
    public int SessionCount { get; set; }
    public int CompletedSessions { get; set; }
}

// ── Premium Users Usage (list theo user, không phải theo feature) ──────────

public class PremiumUserUsageDto
{
    public string UserId { get; set; } = "";
    public string Name { get; set; } = "";
    public string Email { get; set; } = "";
    /// <summary>User có đang trong thời hạn Premium hiệu lực tại thời điểm xem hay không
    /// (danh sách vẫn liệt kê cả user Premium đã hết hạn).</summary>
    public bool IsCurrentlyPremium { get; set; }
    public int EquipmentInfoCount { get; set; }
    public int BodyCheckCount { get; set; }
    public int FormCheckVideoCount { get; set; }
    public int GenerateWorkoutPlanCount { get; set; }
}

public class FeatureUsageDetailDto
{
    public DateTime CreatedAt { get; set; }
    /// <summary>Input người dùng đã nhập (JSON) — chỉ có ở GenerateWorkoutPlan, null với 3 tính năng còn lại.</summary>
    public string? RequestSnapshot { get; set; }
    public string ResponseSummary { get; set; } = "";
}
