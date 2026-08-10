using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.DTOs.AIModel;
using GymSupport.Repository.Models.Entities;
using GymSupport.Service.Interfaces;

namespace GymSupport.Service.Services;

/// <summary>
/// Tính toán báo cáo đánh giá buổi tập. Mọi con số (Score, Grade, Summary,
/// Highlights, Improvements, Recovery, Nutrition) được tính xác định (deterministic)
/// ngay tại đây bằng C# - AI chỉ được gọi (1 lần, cache lại) để viết phần tường
/// thuật ngắn dựa trên các số liệu đã có, giữ chi phí/usage ở mức tối thiểu.
/// </summary>
public class WorkoutEvaluationService : IWorkoutEvaluationService
{
    private static readonly Dictionary<string, int> BaseRecoveryHours = new(StringComparer.OrdinalIgnoreCase)
    {
        ["Legs"] = 72,
        ["Back"] = 72,
        ["Chest"] = 48,
        ["Shoulders"] = 48,
        ["Arms"] = 36,
        ["Abs"] = 24,
        ["Core"] = 24,
    };

    private readonly IWorkoutSessionLogRepository _sessionRepository;
    private readonly IWorkoutPlanRepository _workoutPlanRepository;
    private readonly ICustomerRepository _customerRepository;
    private readonly IMuscleRepository _muscleRepository;
    private readonly IAiUsageService _aiUsageService;
    private readonly IAIService _aiService;

    public WorkoutEvaluationService(
        IWorkoutSessionLogRepository sessionRepository,
        IWorkoutPlanRepository workoutPlanRepository,
        ICustomerRepository customerRepository,
        IMuscleRepository muscleRepository,
        IAiUsageService aiUsageService,
        IAIService aiService)
    {
        _sessionRepository = sessionRepository;
        _workoutPlanRepository = workoutPlanRepository;
        _customerRepository = customerRepository;
        _muscleRepository = muscleRepository;
        _aiUsageService = aiUsageService;
        _aiService = aiService;
    }

    public async Task<(AiUsageCheckResult check, WorkoutEvaluation? evaluation)> EvaluateAsync(
        string sessionLogId,
        string userId)
    {
        var session = await _sessionRepository.GetByIdAsync(sessionLogId);
        if (session == null || session.UserId != userId)
        {
            return (AiUsageCheckResult.Deny("NOT_FOUND", "Không tìm thấy buổi tập."), null);
        }

        if (session.Status != "COMPLETED")
        {
            return (AiUsageCheckResult.Deny(
                "INVALID_STATE",
                "Chỉ có thể đánh giá buổi tập đã hoàn thành."), null);
        }

        if (session.Evaluation != null)
        {
            return (AiUsageCheckResult.Allow(), session.Evaluation);
        }

        var usageCheck = await _aiUsageService.CheckAndReserveAsync(userId, AiFeature.EvaluateWorkout);
        if (!usageCheck.Allowed)
        {
            return (usageCheck, null);
        }

        var history = (await _sessionRepository.GetByUserIdAsync(userId))
            .Where(x => x.Id != session.Id && x.Status == "COMPLETED")
            .OrderByDescending(x => x.EndTime ?? x.StartTime)
            .ToList();

        var customer = await _customerRepository.GetByUserIdAsync(userId);
        var weightKg = customer is { WeightKg: > 0 } ? customer.WeightKg : 70;

        var muscles = (await _muscleRepository.GetAllAsync())
            .ToDictionary(x => x.Id, x => x);

        var summary = BuildSummary(session, weightKg);
        var completionRatio = CalculateCompletionRatio(session);
        var volumeRatio = CalculateVolumeRatio(session, history);
        var paceRatio = CalculatePaceRatio(session);
        var varietyRatio = CalculateVarietyRatio(session);

        var score = (int)Math.Round(Math.Clamp(
            completionRatio * 40 + Math.Min(1.1, volumeRatio) * 30 + paceRatio * 15 + varietyRatio * 15,
            0,
            100));
        var grade = ScoreToGrade(score);

        var highlights = BuildHighlights(session, history, completionRatio, volumeRatio);
        var improvements = BuildImprovements(session, paceRatio, varietyRatio);
        improvements.AddRange(BuildWeightSelectionNotes(session));
        improvements.AddRange(BuildBalanceNotes(session, history, muscles));
        var recovery = BuildRecovery(session, muscles);
        var nutrition = BuildNutrition(session, weightKg, summary.DurationMinutes);
        var comparison = BuildComparison(session, history, weightKg);
        var streak = WorkoutSessionLogService.CalculateScheduleAwareStreak(
            history.Append(session).ToList());
        var nextPlanned = await FindNextPlannedSessionAsync(session);

        var metrics = new WorkoutEvaluationMetricsDto
        {
            Focus = session.Focus,
            Score = score,
            Grade = grade,
            DurationMinutes = summary.DurationMinutes,
            ExerciseCount = summary.ExerciseCount,
            TotalSets = summary.TotalSets,
            TotalReps = summary.TotalReps,
            TotalVolumeKg = summary.TotalVolumeKg,
            EstimatedCalories = summary.EstimatedCalories,
            ComparisonSummary = BuildComparisonSummaryText(comparison),
            Highlights = highlights,
            Improvements = improvements,
            MuscleRecoverySummary = recovery
                .Select(r => $"{r.MuscleCategory}: {r.Status} (~{r.RecoveryHours}h)")
                .ToList(),
            ProteinGrams = nutrition.ProteinGrams,
            WaterLiters = nutrition.WaterLiters,
            CurrentStreak = streak,
            NextPlannedSession = nextPlanned,
        };

        var narrative = await _aiService.EvaluateWorkoutAsync(userId, metrics);

        nutrition.MealSuggestion = string.IsNullOrWhiteSpace(narrative.MealSuggestion)
            ? nutrition.MealSuggestion
            : narrative.MealSuggestion;

        var evaluation = new WorkoutEvaluation
        {
            Score = score,
            Grade = grade,
            Summary = summary,
            Comparison = comparison,
            Highlights = highlights,
            Improvements = improvements,
            Recovery = recovery,
            Nutrition = nutrition,
            NarrativeSummary = narrative.NarrativeSummary,
            SuggestedNextWorkout = narrative.SuggestedNextWorkout,
            MotivationalMessage = narrative.MotivationalMessage,
            GeneratedAt = DateTime.UtcNow,
        };

        session.Evaluation = evaluation;
        await _sessionRepository.UpdateAsync(session.Id, session);

        return (AiUsageCheckResult.Allow(), evaluation);
    }

    private static WorkoutEvaluationSummary BuildSummary(WorkoutSessionLog session, int weightKg)
    {
        var durationMinutes = Math.Max(0, session.TotalDurationSeconds / 60);
        var totalReps = session.Exercises
            .SelectMany(e => e.Sets)
            .Where(s => s.Status == "COMPLETED")
            .Sum(s => s.Reps ?? 0);

        // Ước tính calo dựa trên MET ~6 cho tập kháng lực (kcal = MET * cân nặng(kg) * giờ tập).
        const double resistanceTrainingMet = 6.0;
        var estimatedCalories = (int)Math.Round(resistanceTrainingMet * weightKg * (durationMinutes / 60.0));

        return new WorkoutEvaluationSummary
        {
            DurationMinutes = durationMinutes,
            ExerciseCount = session.Exercises.Count(e => e.Sets.Any(s => s.Status == "COMPLETED")),
            TotalSets = session.TotalSets,
            TotalReps = totalReps,
            TotalVolumeKg = Math.Round(session.TotalVolume, 1),
            EstimatedCalories = estimatedCalories,
        };
    }

    private static double CalculateCompletionRatio(WorkoutSessionLog session)
    {
        var plannedSets = session.Exercises.Sum(e => e.PlannedSets);
        if (plannedSets > 0)
        {
            return Math.Min(1.0, session.TotalSets / (double)plannedSets);
        }

        // Buổi tập tự do (không theo plan) - đánh giá theo tỉ lệ bài tập có ít nhất 1 set hoàn thành.
        if (session.Exercises.Count == 0) return 1.0;
        var completedExercises = session.Exercises.Count(e => e.Sets.Any(s => s.Status == "COMPLETED"));
        return completedExercises / (double)session.Exercises.Count;
    }

    private static double CalculateVolumeRatio(WorkoutSessionLog session, List<WorkoutSessionLog> history)
    {
        var comparable = (string.IsNullOrEmpty(session.PlanSessionId)
                ? history.Where(h => h.Name == session.Name)
                : history.Where(h => h.PlanSessionId == session.PlanSessionId))
            .Take(3)
            .ToList();

        if (comparable.Count == 0 || comparable.Average(h => h.TotalVolume) <= 0)
        {
            // Không có dữ liệu để so sánh (bài mới) - cho điểm trung tính, không phạt.
            return 1.0;
        }

        var baseline = comparable.Average(h => h.TotalVolume);
        return session.TotalVolume / baseline;
    }

    /// So sánh trực tiếp với LẦN GẦN NHẤT tập cùng buổi (không phải trung bình nhiều lần
    /// như CalculateVolumeRatio dùng để chấm điểm) - phục vụ hiển thị "so với lần trước".
    private static WorkoutSessionComparison BuildComparison(
        WorkoutSessionLog session,
        List<WorkoutSessionLog> history,
        int weightKg)
    {
        var previous = (string.IsNullOrEmpty(session.PlanSessionId)
                ? history.Where(h => h.Name == session.Name)
                : history.Where(h => h.PlanSessionId == session.PlanSessionId))
            .FirstOrDefault();

        if (previous == null)
        {
            return new WorkoutSessionComparison { HasPrevious = false };
        }

        var volumeDeltaPercent = previous.TotalVolume > 0
            ? Math.Round((session.TotalVolume - previous.TotalVolume) / previous.TotalVolume * 100, 1)
            : 0;

        var currentReps = session.Exercises.SelectMany(e => e.Sets)
            .Where(s => s.Status == "COMPLETED").Sum(s => s.Reps ?? 0);
        var previousReps = previous.Exercises.SelectMany(e => e.Sets)
            .Where(s => s.Status == "COMPLETED").Sum(s => s.Reps ?? 0);

        var currentExercisesCompleted = session.Exercises.Count(e => e.Sets.Any(s => s.Status == "COMPLETED"));
        var previousExercisesCompleted = previous.Exercises.Count(e => e.Sets.Any(s => s.Status == "COMPLETED"));

        var currentAvgWeight = currentReps > 0 ? session.TotalVolume / currentReps : 0;
        var previousAvgWeight = previousReps > 0 ? previous.TotalVolume / previousReps : 0;

        var currentDurationMin = Math.Max(1, session.TotalDurationSeconds / 60);
        var previousDurationMin = Math.Max(1, previous.TotalDurationSeconds / 60);
        var currentDensity = session.TotalVolume / currentDurationMin;
        var previousDensity = previous.TotalVolume / previousDurationMin;

        // Cùng công thức MET dùng ở BuildSummary, áp cho cả 2 buổi để so sánh calo nhất quán.
        const double resistanceTrainingMet = 6.0;
        var currentCalories = (int)Math.Round(resistanceTrainingMet * weightKg * (currentDurationMin / 60.0));
        var previousCalories = (int)Math.Round(resistanceTrainingMet * weightKg * (previousDurationMin / 60.0));

        return new WorkoutSessionComparison
        {
            HasPrevious = true,
            PreviousDate = previous.EndTime ?? previous.StartTime,
            PreviousVolumeKg = Math.Round(previous.TotalVolume, 1),
            VolumeDeltaPercent = volumeDeltaPercent,
            PreviousSets = previous.TotalSets,
            SetsDelta = session.TotalSets - previous.TotalSets,
            PreviousDurationMinutes = previous.TotalDurationSeconds / 60,
            DurationDeltaMinutes = (session.TotalDurationSeconds - previous.TotalDurationSeconds) / 60,
            RepsDelta = currentReps - previousReps,
            ExercisesCompletedDelta = currentExercisesCompleted - previousExercisesCompleted,
            AvgWeightDeltaKg = Math.Round(currentAvgWeight - previousAvgWeight, 1),
            DensityDeltaKgPerMin = Math.Round(currentDensity - previousDensity, 1),
            CaloriesDelta = currentCalories - previousCalories,
        };
    }

    private static string BuildComparisonSummaryText(WorkoutSessionComparison comparison)
    {
        if (!comparison.HasPrevious)
        {
            return "Đây là lần đầu tiên tập buổi này, chưa có dữ liệu để so sánh.";
        }

        var direction = comparison.VolumeDeltaPercent > 0
            ? "tăng"
            : comparison.VolumeDeltaPercent < 0
                ? "giảm"
                : "giữ nguyên";

        return $"So với lần tập buổi này gần nhất ({comparison.PreviousDate:dd/MM}): " +
               $"khối lượng {direction} {Math.Abs(comparison.VolumeDeltaPercent)}%, " +
               $"sets {(comparison.SetsDelta >= 0 ? "+" : "")}{comparison.SetsDelta}, " +
               $"reps {(comparison.RepsDelta >= 0 ? "+" : "")}{comparison.RepsDelta}, " +
               $"mức tạ trung bình {(comparison.AvgWeightDeltaKg >= 0 ? "+" : "")}{comparison.AvgWeightDeltaKg}kg/rep, " +
               $"mật độ tập {(comparison.DensityDeltaKgPerMin >= 0 ? "+" : "")}{comparison.DensityDeltaKgPerMin}kg/phút, " +
               $"thời gian {(comparison.DurationDeltaMinutes >= 0 ? "+" : "")}{comparison.DurationDeltaMinutes} phút, " +
               $"calo {(comparison.CaloriesDelta >= 0 ? "+" : "")}{comparison.CaloriesDelta}.";
    }

    private static double CalculatePaceRatio(WorkoutSessionLog session)
    {
        var timestamps = session.Exercises
            .SelectMany(e => e.Sets)
            .Where(s => s.Status == "COMPLETED")
            .Select(s => s.CreatedAt)
            .OrderBy(t => t)
            .ToList();

        if (timestamps.Count < 2) return 1.0;

        var gaps = new List<double>();
        for (var i = 1; i < timestamps.Count; i++)
        {
            gaps.Add((timestamps[i] - timestamps[i - 1]).TotalSeconds);
        }

        var avgGapSeconds = gaps.Average();

        // Băng nghỉ lý tưởng ~45-150s giữa các set. Lệch quá xa (quá gấp hoặc quá trễ) bị trừ điểm nhẹ.
        const double idealMin = 45.0;
        const double idealMax = 150.0;
        if (avgGapSeconds >= idealMin && avgGapSeconds <= idealMax) return 1.0;

        var distance = avgGapSeconds < idealMin ? idealMin - avgGapSeconds : avgGapSeconds - idealMax;
        return Math.Clamp(1.0 - distance / 180.0, 0.3, 1.0);
    }

    private static double CalculateVarietyRatio(WorkoutSessionLog session)
    {
        var distinctMuscles = session.MuscleExpGains.Count;
        return Math.Min(1.0, distinctMuscles / 3.0);
    }

    private static string ScoreToGrade(int score) => score switch
    {
        >= 95 => "A+",
        >= 88 => "A",
        >= 80 => "B+",
        >= 72 => "B",
        >= 64 => "C+",
        >= 55 => "C",
        _ => "D",
    };

    private static List<string> BuildHighlights(
        WorkoutSessionLog session,
        List<WorkoutSessionLog> history,
        double completionRatio,
        double volumeRatio)
    {
        var highlights = new List<string>();

        if (completionRatio >= 0.99)
        {
            highlights.Add("Hoàn thành đầy đủ buổi tập theo kế hoạch");
        }

        if (volumeRatio > 1.02 && history.Any())
        {
            highlights.Add("Tăng khối lượng tập luyện so với các buổi gần đây");
        }

        foreach (var exercise in session.Exercises)
        {
            var bestSet = exercise.Sets
                .Where(s => s.Status == "COMPLETED")
                .OrderByDescending(s => (s.Weight ?? 0) * (s.Reps ?? 0))
                .FirstOrDefault();
            if (bestSet == null) continue;

            var bestVolume = (bestSet.Weight ?? 0) * (bestSet.Reps ?? 0);
            var historicalBest = history
                .SelectMany(h => h.Exercises.Where(e => e.ExerciseId == exercise.ExerciseId))
                .SelectMany(e => e.Sets.Where(s => s.Status == "COMPLETED"))
                .Select(s => (s.Weight ?? 0) * (s.Reps ?? 0))
                .DefaultIfEmpty(0)
                .Max();

            if (bestVolume > historicalBest && bestVolume > 0)
            {
                highlights.Add($"PR mới: {exercise.ExerciseName} {bestSet.Weight}kg x {bestSet.Reps}");
            }
        }

        return highlights;
    }

    private static List<string> BuildImprovements(
        WorkoutSessionLog session,
        double paceRatio,
        double varietyRatio)
    {
        var improvements = new List<string>();

        var skipped = session.Exercises
            .Where(e => e.PlannedSets > 0 && !e.Sets.Any(s => s.Status == "COMPLETED"))
            .Select(e => e.ExerciseName)
            .ToList();
        if (skipped.Count > 0)
        {
            improvements.Add($"Đã bỏ qua: {string.Join(", ", skipped)}");
        }

        if (paceRatio < 0.7)
        {
            improvements.Add("Nhịp độ nghỉ giữa các set chưa hợp lý - cân nhắc nghỉ khoảng 60-90 giây để phục hồi tốt hơn");
        }

        var rpes = session.Exercises
            .SelectMany(e => e.Sets)
            .Where(s => s.Status == "COMPLETED" && s.Rpe.HasValue)
            .Select(s => s.Rpe!.Value)
            .ToList();
        if (rpes.Count > 0 && rpes.Average() < 6)
        {
            improvements.Add("Cường độ (RPE trung bình) hơi thấp - có thể tăng thêm mức tạ hoặc số reps");
        }

        if (varietyRatio < 0.5)
        {
            improvements.Add("Buổi tập tập trung vào ít nhóm cơ - cân nhắc đa dạng bài tập hơn");
        }

        return improvements;
    }

    /// Phân tích mức tạ theo từng bài dựa trên xu hướng reps qua các set:
    /// reps giảm mạnh liên tục -> tạ có thể quá nặng; vượt trần rep mục tiêu ở
    /// mọi set -> tạ có thể quá nhẹ. Chỉ xét bài có từ 3 set hoàn thành trở lên
    /// để tránh kết luận vội trên dữ liệu quá ít.
    private static List<string> BuildWeightSelectionNotes(WorkoutSessionLog session)
    {
        var notes = new List<string>();

        foreach (var exercise in session.Exercises)
        {
            var completedSets = exercise.Sets
                .Where(s => s.Status == "COMPLETED" && s.Reps.HasValue)
                .OrderBy(s => s.SetNumber)
                .ToList();

            if (completedSets.Count < 3) continue;

            var repsSequence = completedSets.Select(s => s.Reps!.Value).ToList();
            var firstReps = repsSequence.First();
            var lastReps = repsSequence.Last();

            var isConsistentlyDeclining = true;
            for (var i = 1; i < repsSequence.Count; i++)
            {
                if (repsSequence[i] > repsSequence[i - 1])
                {
                    isConsistentlyDeclining = false;
                    break;
                }
            }

            if (isConsistentlyDeclining && firstReps > 0 &&
                (firstReps - lastReps) / (double)firstReps >= 0.4)
            {
                notes.Add(
                    $"{exercise.ExerciseName}: reps giảm mạnh qua các set ({string.Join("-", repsSequence)}) " +
                    "- mức tạ có thể đang hơi nặng, cân nhắc giảm nhẹ để giữ form tốt hơn.");
                continue;
            }

            var range = ParseRepRange(exercise.PlannedReps);
            if (range.HasValue && repsSequence.All(r => r > range.Value.max))
            {
                notes.Add(
                    $"{exercise.ExerciseName}: hoàn thành vượt mức reps mục tiêu " +
                    $"({range.Value.min}-{range.Value.max}) ở mọi set - có thể tăng nhẹ mức tạ để tối ưu hiệu quả.");
            }
        }

        return notes;
    }

    private static (int min, int max)? ParseRepRange(string plannedReps)
    {
        var numbers = System.Text.RegularExpressions.Regex.Matches(plannedReps ?? "", @"\d+")
            .Select(m => int.Parse(m.Value))
            .ToList();
        if (numbers.Count == 0) return null;
        return (numbers.Min(), numbers.Max());
    }

    /// Phát hiện nhóm cơ bị "bỏ quên": từng xuất hiện đều đặn trong khoảng 10 buổi
    /// tập trước đó nhưng không có mặt trong 4 buổi gần nhất (kể cả buổi hôm nay).
    /// Cần đủ lịch sử (>=3 buổi cũ) mới cảnh báo, tránh báo sai với tài khoản mới.
    private static List<string> BuildBalanceNotes(
        WorkoutSessionLog session,
        List<WorkoutSessionLog> history,
        Dictionary<string, Muscle> muscles)
    {
        string CategoryOf(string muscleId) =>
            muscles.TryGetValue(muscleId, out var m) && !string.IsNullOrWhiteSpace(m.Category)
                ? m.Category
                : "Khác";

        var recentCategories = history.Take(4)
            .Append(session)
            .SelectMany(s => s.MuscleExpGains.Select(g => CategoryOf(g.MuscleId)))
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        var olderSessions = history.Skip(4).Take(10).ToList();
        var olderCategories = olderSessions
            .SelectMany(s => s.MuscleExpGains.Select(g => CategoryOf(g.MuscleId)))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        var neglected = olderCategories.Where(c => !recentCategories.Contains(c)).ToList();

        if (neglected.Count == 0 || olderSessions.Count < 3)
        {
            return new List<string>();
        }

        return new List<string>
        {
            $"Đã khá lâu chưa tập nhóm cơ: {string.Join(", ", neglected)} - cân nhắc bổ sung vào lịch tập sắp tới để cơ thể phát triển cân bằng.",
        };
    }

    private static List<MuscleRecoveryStatus> BuildRecovery(
        WorkoutSessionLog session,
        Dictionary<string, Muscle> muscles)
    {
        var byCategory = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
        foreach (var gain in session.MuscleExpGains)
        {
            var category = muscles.TryGetValue(gain.MuscleId, out var muscle) && !string.IsNullOrWhiteSpace(muscle.Category)
                ? muscle.Category
                : "Khác";
            byCategory[category] = byCategory.GetValueOrDefault(category) + gain.ExpGained;
        }

        var referenceTime = session.EndTime ?? DateTime.UtcNow;
        var result = new List<MuscleRecoveryStatus>();
        foreach (var (category, exp) in byCategory.OrderByDescending(x => x.Value))
        {
            var baseHours = BaseRecoveryHours.GetValueOrDefault(category, 36);
            var recoveryHours = (int)Math.Round(baseHours * (1 + Math.Min(1.0, exp / 150.0)));
            var status = recoveryHours >= 48 ? "Cần nghỉ" : recoveryHours >= 24 ? "Đang hồi phục" : "Sẵn sàng sớm";

            result.Add(new MuscleRecoveryStatus
            {
                MuscleCategory = category,
                Status = status,
                RecoveryHours = recoveryHours,
                ReadyAt = referenceTime.AddHours(recoveryHours),
            });
        }

        return result;
    }

    private static NutritionRecommendation BuildNutrition(WorkoutSessionLog session, int weightKg, int durationMinutes)
    {
        var proteinGrams = (int)Math.Round(weightKg * 1.8);
        var waterLiters = Math.Round(weightKg * 0.033 + (durationMinutes / 15.0) * 0.2, 1);

        return new NutritionRecommendation
        {
            ProteinGrams = proteinGrams,
            WaterLiters = waterLiters,
            MealSuggestion = "Ưu tiên đạm nạc và tinh bột phức hợp trong bữa ăn sau tập.",
        };
    }

    private async Task<string?> FindNextPlannedSessionAsync(WorkoutSessionLog session)
    {
        if (string.IsNullOrEmpty(session.WorkoutPlanId)) return null;

        var plan = await _workoutPlanRepository.GetByIdAsync(session.WorkoutPlanId);
        if (plan == null || plan.Sessions.Count == 0) return null;

        var currentIndex = plan.Sessions.FindIndex(s => s.Id == session.PlanSessionId);
        if (currentIndex < 0) return plan.Sessions.First().Focus;

        var next = plan.Sessions[(currentIndex + 1) % plan.Sessions.Count];
        return $"{next.Focus} ({next.DayOfWeek})";
    }
}
