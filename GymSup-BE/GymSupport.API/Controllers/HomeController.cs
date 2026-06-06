using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace GymSupport.API.Controllers;

[ApiController]
[Route("api/home")]
[Authorize]
public class HomeController : ControllerBase
{
    private readonly IWorkoutPlanRepository _workoutPlanRepository;
    private readonly IWorkoutSessionLogRepository _workoutSessionLogRepository;
    private readonly ICustomerRepository _customerRepository;
    private readonly IExerciseRepository _exerciseRepository;
    private readonly IMuscleRepository _muscleRepository;

    public HomeController(
        IWorkoutPlanRepository workoutPlanRepository,
        IWorkoutSessionLogRepository workoutSessionLogRepository,
        ICustomerRepository customerRepository,
        IExerciseRepository exerciseRepository,
        IMuscleRepository muscleRepository)
    {
        _workoutPlanRepository = workoutPlanRepository;
        _workoutSessionLogRepository = workoutSessionLogRepository;
        _customerRepository = customerRepository;
        _exerciseRepository = exerciseRepository;
        _muscleRepository = muscleRepository;
    }

    [HttpGet("{userId}")]
    public async Task<IActionResult> GetHome(string userId)
    {
        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub);

        if (string.IsNullOrWhiteSpace(currentUserId))
            return Unauthorized();

        if (currentUserId != userId)
            return Forbid();

        var plans = await _workoutPlanRepository.GetByUserIdAsync(userId);
        var history = await _workoutSessionLogRepository.GetByUserIdAsync(userId);
        var customer = await _customerRepository.GetByUserIdAsync(userId);
        var exercises = (await _exerciseRepository.GetAllAsync()).ToList();
        var muscles = await _muscleRepository.GetAllAsync();

        var todayPlan = BuildTodayPlan(plans, exercises, muscles);
        var nutrition = BuildNutrition(customer);
        var muscleProgress = BuildMuscleProgress(history, exercises, muscles);

        return Ok(new
        {
            history,
            plans,
            todayPlan,
            nutrition,
            muscleProgress,
            streak = CalculateStreak(history),
            workoutCount = history.Count(x => x.Status == "COMPLETED")
        });
    }

    private static object? BuildTodayPlan(
        List<WorkoutPlan> plans,
        List<Exercise> exercises,
        List<Muscle> muscles)
    {
        var usablePlans = plans
            .Where(x => x.IsActive)
            .OrderByDescending(x => x.CreatedAt)
            .ToList();
        if (!usablePlans.Any())
            usablePlans = plans.OrderByDescending(x => x.CreatedAt).ToList();

        var today = DateTime.Now.DayOfWeek.ToString();
        WorkoutSession? selectedSession = null;

        foreach (var plan in usablePlans)
        {
            selectedSession = plan.Sessions.FirstOrDefault(x =>
                MatchesToday(x.DayOfWeek, today));

            if (selectedSession != null)
                break;
        }

        if (selectedSession == null)
        {
            selectedSession = usablePlans
                .SelectMany(x => x.Sessions)
                .FirstOrDefault(x => string.Equals(x.DayOfWeek, "Today", StringComparison.OrdinalIgnoreCase));
        }

        if (selectedSession == null)
            return null;

        var exerciseMap = exercises.ToDictionary(x => x.Id, x => x);
        var muscleMap = muscles.ToDictionary(x => x.Id, x => x);

        var sessionExercises = selectedSession.Exercises.Select(item =>
        {
            exerciseMap.TryGetValue(item.ExerciseId, out var exercise);

            var muscleName = "Unknown";
            var firstImpact = exercise?.MuscleImpacts.FirstOrDefault();
            if (firstImpact != null && muscleMap.TryGetValue(firstImpact.MuscleId, out var muscle))
                muscleName = string.IsNullOrWhiteSpace(muscle.Name) ? muscle.Category : muscle.Name;

            return new
            {
                id = item.ExerciseId,
                name = string.IsNullOrWhiteSpace(item.ExerciseName)
                    ? exercise?.Name ?? "Exercise"
                    : item.ExerciseName,
                muscle = muscleName,
                sets = item.Sets,
                reps = item.Reps,
                notes = item.Notes
            };
        }).ToList();

        return new
        {
            day = DisplayDay(selectedSession.DayOfWeek),
            focus = selectedSession.Focus,
            exercises = sessionExercises
        };
    }

    private static bool MatchesToday(string? value, string today)
    {
        if (string.IsNullOrWhiteSpace(value))
            return false;

        var normalized = value.Trim();
        if (string.Equals(normalized, "Today", StringComparison.OrdinalIgnoreCase))
            return true;

        return string.Equals(normalized, today, StringComparison.OrdinalIgnoreCase)
            || string.Equals(normalized, EnglishDayToVietnamese(today), StringComparison.OrdinalIgnoreCase)
            || string.Equals(normalized, EnglishDayToVietnameseNoAccent(today), StringComparison.OrdinalIgnoreCase);
    }

    private static string DisplayDay(string? day)
    {
        if (string.IsNullOrWhiteSpace(day))
            return "Today";

        if (string.Equals(day, "Today", StringComparison.OrdinalIgnoreCase))
            return "Today";

        return $"{EnglishDayToVietnamese(day)} - {day}";
    }

    private static string EnglishDayToVietnamese(string day)
    {
        return day.ToLowerInvariant() switch
        {
            "monday" => "Thứ 2",
            "tuesday" => "Thứ 3",
            "wednesday" => "Thứ 4",
            "thursday" => "Thứ 5",
            "friday" => "Thứ 6",
            "saturday" => "Thứ 7",
            "sunday" => "Chủ nhật",
            _ => day
        };
    }

    private static string EnglishDayToVietnameseNoAccent(string day)
    {
        return day.ToLowerInvariant() switch
        {
            "monday" => "Thu 2",
            "tuesday" => "Thu 3",
            "wednesday" => "Thu 4",
            "thursday" => "Thu 5",
            "friday" => "Thu 6",
            "saturday" => "Thu 7",
            "sunday" => "Chu nhat",
            _ => day
        };
    }

    private static object BuildNutrition(Customer? customer)
    {
        if (customer == null)
        {
            return new
            {
                calories = "—",
                protein = "—",
                water = "—"
            };
        }

        var weight = customer.WeightKg;
        var height = customer.HeightCm;
        var age = customer.Age;

        if (weight <= 0 || height <= 0 || age <= 0)
        {
            return new
            {
                calories = "—",
                protein = weight > 0 ? $"{Math.Round(weight * 1.8)}g" : "—",
                water = weight > 0 ? $"{Math.Round(weight * 35 / 1000.0, 1)}L" : "—"
            };
        }

        var gender = customer.Gender?.ToLowerInvariant() ?? "";
        var goal = customer.Goal?.ToLowerInvariant() ?? "";
        var bmr = gender.Contains("nữ") || gender.Contains("female")
            ? 10 * weight + 6.25 * height - 5 * age - 161
            : 10 * weight + 6.25 * height - 5 * age + 5;

        var calories = bmr * 1.45;
        if (goal.Contains("giảm") || goal.Contains("lose"))
            calories -= 300;
        else if (goal.Contains("tăng cơ") || goal.Contains("strength") || goal.Contains("muscle"))
            calories += 250;

        return new
        {
            calories = $"{Math.Round(calories)} kcal",
            protein = $"{Math.Round(weight * 1.8)}g",
            water = $"{Math.Round(weight * 35 / 1000.0, 1)}L"
        };
    }

    private static List<object> BuildMuscleProgress(
        List<WorkoutSessionLog> history,
        List<Exercise> exercises,
        List<Muscle> muscles)
    {
        var expByMuscle = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);

        foreach (var log in history)
        {
            foreach (var gain in log.MuscleExpGains)
            {
                if (string.IsNullOrWhiteSpace(gain.MuscleName))
                    continue;

                expByMuscle[gain.MuscleName] = expByMuscle.GetValueOrDefault(gain.MuscleName) + gain.ExpGained;
            }
        }

        if (!expByMuscle.Any())
        {
            var exerciseMap = exercises.ToDictionary(x => x.Id, x => x);
            var muscleMap = muscles.ToDictionary(x => x.Id, x => x);

            foreach (var log in history.Where(x => x.Status == "COMPLETED"))
            {
                foreach (var item in log.Exercises)
                {
                    if (!exerciseMap.TryGetValue(item.ExerciseId, out var exercise))
                        continue;

                    var impact = exercise.MuscleImpacts.FirstOrDefault();
                    if (impact == null || !muscleMap.TryGetValue(impact.MuscleId, out var muscle))
                        continue;

                    var muscleName = string.IsNullOrWhiteSpace(muscle.Name) ? muscle.Category : muscle.Name;
                    expByMuscle[muscleName] = expByMuscle.GetValueOrDefault(muscleName) + 25;
                }
            }
        }

        return expByMuscle
            .OrderByDescending(x => x.Value)
            .Select(x =>
            {
                var exp = x.Value;
                var level = exp / 100 + 1;
                var progressXp = exp % 100;

                return new
                {
                    name = x.Key,
                    level = $"Lv {level}",
                    progress = progressXp / 100.0,
                    xp = $"{progressXp}/100 XP"
                } as object;
            })
            .ToList();
    }

    private static int CalculateStreak(List<WorkoutSessionLog> history)
    {
        var completedDays = history
            .Where(x => x.Status == "COMPLETED")
            .Select(x => (x.EndTime ?? x.StartTime).ToLocalTime().Date)
            .ToHashSet();

        var cursor = DateTime.Now.Date;
        if (!completedDays.Contains(cursor))
            cursor = cursor.AddDays(-1);

        var streak = 0;
        while (completedDays.Contains(cursor))
        {
            streak++;
            cursor = cursor.AddDays(-1);
        }

        return streak;
    }
}
