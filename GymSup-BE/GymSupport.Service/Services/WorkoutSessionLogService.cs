using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.DTOs.WorkoutPlan;
using GymSupport.Repository.Models.Entities;
using GymSupport.Service.Interfaces;

namespace GymSupport.Service.Services;

public class WorkoutSessionLogService : IWorkoutSessionLogService
{
    private readonly IWorkoutSessionLogRepository _sessionLogRepository;
    private readonly IWorkoutPlanRepository _workoutPlanRepository;

    public WorkoutSessionLogService(
        IWorkoutSessionLogRepository sessionLogRepository,
        IWorkoutPlanRepository workoutPlanRepository)
    {
        _sessionLogRepository = sessionLogRepository;
        _workoutPlanRepository = workoutPlanRepository;
    }

    public async Task<WorkoutSessionLog> StartSessionAsync(
        StartWorkoutSessionRequestDto dto)
    {
        var activeSession =
            await _sessionLogRepository.GetActiveByUserIdAsync(dto.UserId);

        if (activeSession != null)
        {
            throw new Exception("Bạn đang có một buổi tập chưa hoàn thành.");
        }

        var workoutPlan =
            await _workoutPlanRepository.GetByIdAsync(dto.WorkoutPlanId);

        if (workoutPlan == null)
        {
            throw new Exception("Không tìm thấy workout plan.");
        }

        var planSession = workoutPlan.Sessions
            .FirstOrDefault(x => x.Id == dto.PlanSessionId);

        if (planSession == null)
        {
            throw new Exception("Không tìm thấy buổi tập trong workout plan.");
        }

        var exerciseLogs = planSession.Exercises
            .Select((exercise, index) => new WorkoutExerciseLog
            {
                ExerciseId = exercise.ExerciseId,
                ExerciseName = exercise.ExerciseName,
                MuscleIds = new List<string>(),
                OrderIndex = index + 1,
                Status = "PENDING",
                Sets = new List<WorkoutSetLog>()
            })
            .ToList();

        var sessionLog = new WorkoutSessionLog
        {
            UserId = dto.UserId,
            WorkoutPlanId = dto.WorkoutPlanId,
            PlanSessionId = dto.PlanSessionId,
            Name = string.IsNullOrWhiteSpace(planSession.Focus)
                ? "Workout Session"
                : planSession.Focus,
            Focus = planSession.Focus,
            StartTime = DateTime.UtcNow,
            Status = "IN_PROGRESS",
            Exercises = exerciseLogs,
            TotalDurationSeconds = 0,
            TotalSets = 0,
            TotalVolume = 0,
            TotalExpGained = 0
        };

        return await _sessionLogRepository.CreateAsync(sessionLog);
    }

    public async Task<WorkoutSessionLog?> GetActiveSessionAsync(
        string userId)
    {
        return await _sessionLogRepository.GetActiveByUserIdAsync(userId);
    }

    public async Task<WorkoutSessionLog> AddSetAsync(
        string sessionLogId,
        string exerciseLogId,
        AddWorkoutSetRequestDto dto)
    {
        var session =
            await _sessionLogRepository.GetByIdAsync(sessionLogId);

        if (session == null)
        {
            throw new Exception("Không tìm thấy buổi tập.");
        }

        if (session.Status != "IN_PROGRESS")
        {
            throw new Exception("Chỉ có thể thêm set khi buổi tập đang diễn ra.");
        }

        var exerciseLog =
            session.Exercises.FirstOrDefault(x => x.Id == exerciseLogId);

        if (exerciseLog == null)
        {
            throw new Exception("Không tìm thấy bài tập trong buổi tập.");
        }

        var setLog = new WorkoutSetLog
        {
            SetNumber = dto.SetNumber,
            Weight = dto.Weight,
            Reps = dto.Reps,
            DurationSeconds = dto.DurationSeconds,
            Rpe = dto.Rpe,
            Status = "COMPLETED",
            CreatedAt = DateTime.UtcNow
        };

        exerciseLog.Sets.Add(setLog);
        exerciseLog.Status = "IN_PROGRESS";

        session.TotalSets = session.Exercises
            .SelectMany(x => x.Sets)
            .Count(x => x.Status == "COMPLETED");

        session.TotalVolume = session.Exercises
            .SelectMany(x => x.Sets)
            .Where(x => x.Status == "COMPLETED")
            .Sum(x => (x.Weight ?? 0) * (x.Reps ?? 0));

        await _sessionLogRepository.UpdateAsync(session.Id, session);

        return session;
    }

    public async Task<WorkoutSessionLog> FinishSessionAsync(
        string sessionLogId)
    {
        var session =
            await _sessionLogRepository.GetByIdAsync(sessionLogId);

        if (session == null)
        {
            throw new Exception("Không tìm thấy buổi tập.");
        }

        if (session.Status != "IN_PROGRESS" && session.Status != "PAUSED")
        {
            throw new Exception("Buổi tập này không thể kết thúc.");
        }

        session.EndTime = DateTime.UtcNow;
        session.Status = "COMPLETED";

        session.TotalDurationSeconds =
            (int)(session.EndTime.Value - session.StartTime).TotalSeconds;

        session.TotalSets = session.Exercises
            .SelectMany(x => x.Sets)
            .Count(x => x.Status == "COMPLETED");

        session.TotalVolume = session.Exercises
            .SelectMany(x => x.Sets)
            .Where(x => x.Status == "COMPLETED")
            .Sum(x => (x.Weight ?? 0) * (x.Reps ?? 0));

        foreach (var exercise in session.Exercises)
        {
            if (exercise.Sets.Any(x => x.Status == "COMPLETED"))
            {
                exercise.Status = "COMPLETED";
            }
        }

        await _sessionLogRepository.UpdateAsync(session.Id, session);

        return session;
    }

    public async Task<List<WorkoutSessionLog>> GetHistoryAsync(
        string userId)
    {
        return await _sessionLogRepository.GetByUserIdAsync(userId);
    }
}