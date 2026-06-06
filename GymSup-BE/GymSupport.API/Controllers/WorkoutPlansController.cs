using GymSupport.Repository.Models.Entities;
using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.DTOs.WorkoutPlan;
using Microsoft.AspNetCore.Mvc;

namespace GymSupport.API.Controllers
{
    [Route("api/workoutplans")]
    [ApiController]
    public class WorkoutPlansController : ControllerBase
    {
        private readonly IWorkoutPlanRepository _repository;

        public WorkoutPlansController(
            IWorkoutPlanRepository repository)
        {
            _repository = repository;
        }

        #region WorkoutPlan

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var plans = await _repository.GetAllAsync();

            return Ok(plans);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(string id)
        {
            var plan = await _repository.GetByIdAsync(id);

            if (plan == null)
                return NotFound("Workout plan not found");

            return Ok(plan);
        }

        [HttpGet("user/{userId}")]
        public async Task<IActionResult> GetByUser(string userId)
        {
            var plans = await _repository.GetByUserIdAsync(userId);

            return Ok(plans);
        }

        [HttpPost]
        public async Task<IActionResult> Create(
            [FromBody] CreateWorkoutPlanDto dto)
        {
            if (!string.Equals(dto.Name, "Quick Workout", StringComparison.OrdinalIgnoreCase))
            {
                var currentPlans = await _repository.GetByUserIdAsync(dto.UserId);
                foreach (var currentPlan in currentPlans.Where(x => x.IsActive))
                {
                    currentPlan.IsActive = false;
                    await _repository.UpdateAsync(currentPlan);
                }
            }

            var plan = new WorkoutPlan
            {
                UserId = dto.UserId,
                Name = dto.Name,
                Goal = dto.Goal,
                DaysPerWeek = dto.DaysPerWeek,
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            await _repository.CreateAsync(plan);

            return Ok(plan);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(string id)
        {
            var plan = await _repository.GetByIdAsync(id);

            if (plan == null)
                return NotFound("Workout plan not found");

            await _repository.DeleteAsync(id);

            return NoContent();
        }

        #endregion

        #region Session

        [HttpPost("{planId}/sessions")]
        public async Task<IActionResult> AddSession(
            string planId,
            [FromBody] CreateSessionDto dto)
        {
            var plan = await _repository.GetByIdAsync(planId);

            if (plan == null)
                return NotFound("Workout plan not found");

            plan.Sessions.Add(new WorkoutSession
            {
                Id = Guid.NewGuid().ToString(),
                DayOfWeek = dto.DayOfWeek,
                Focus = dto.Focus
            });

            await _repository.UpdateAsync(plan);

            return Ok(plan);
        }

        [HttpPut("{planId}/sessions/{sessionId}")]
        public async Task<IActionResult> UpdateSession(
            string planId,
            string sessionId,
            [FromBody] UpdateSessionDto dto)
        {
            var plan = await _repository.GetByIdAsync(planId);

            if (plan == null)
                return NotFound("Workout plan not found");

            var session = plan.Sessions
                .FirstOrDefault(x => x.Id == sessionId);

            if (session == null)
                return NotFound("Session not found");

            session.DayOfWeek = dto.DayOfWeek;
            session.Focus = dto.Focus;

            await _repository.UpdateAsync(plan);

            return Ok(session);
        }

        [HttpDelete("{planId}/sessions/{sessionId}")]
        public async Task<IActionResult> DeleteSession(
            string planId,
            string sessionId)
        {
            var plan = await _repository.GetByIdAsync(planId);

            if (plan == null)
                return NotFound("Workout plan not found");

            var session = plan.Sessions
                .FirstOrDefault(x => x.Id == sessionId);

            if (session == null)
                return NotFound("Session not found");

            plan.Sessions.Remove(session);

            await _repository.UpdateAsync(plan);

            return NoContent();
        }

        #endregion

        #region Exercise In Session

        [HttpPost("{planId}/sessions/{sessionId}/exercises")]
        public async Task<IActionResult> AddExercise(
            string planId,
            string sessionId,
            [FromBody] AddExerciseToSessionDto dto)
        {
            var plan = await _repository.GetByIdAsync(planId);

            if (plan == null)
                return NotFound("Workout plan not found");

            var session = plan.Sessions
                .FirstOrDefault(x => x.Id == sessionId);

            if (session == null)
                return NotFound("Session not found");

            session.Exercises.Add(new ExerciseInSession
            {
                ExerciseId = dto.ExerciseId,
                ExerciseName = dto.ExerciseName ?? string.Empty,
                Sets = dto.Sets,
                Reps = dto.Reps,
                Notes = dto.Notes
            });

            await _repository.UpdateAsync(plan);

            return Ok(session);
        }

        [HttpPut("{planId}/sessions/{sessionId}/exercises/{exerciseId}")]
        public async Task<IActionResult> UpdateExercise(
            string planId,
            string sessionId,
            string exerciseId,
            [FromBody] UpdateExerciseInSessionDto dto)
        {
            var plan = await _repository.GetByIdAsync(planId);

            if (plan == null)
                return NotFound("Workout plan not found");

            var session = plan.Sessions
                .FirstOrDefault(x => x.Id == sessionId);

            if (session == null)
                return NotFound("Session not found");

            var exercise = session.Exercises
                .FirstOrDefault(x => x.ExerciseId == exerciseId);

            if (exercise == null)
                return NotFound("Exercise not found");

            exercise.Sets = dto.Sets;
            exercise.Reps = dto.Reps;
            exercise.Notes = dto.Notes;

            await _repository.UpdateAsync(plan);

            return Ok(exercise);
        }

        [HttpDelete("{planId}/sessions/{sessionId}/exercises/{exerciseId}")]
        public async Task<IActionResult> DeleteExercise(
            string planId,
            string sessionId,
            string exerciseId)
        {
            var plan = await _repository.GetByIdAsync(planId);

            if (plan == null)
                return NotFound("Workout plan not found");

            var session = plan.Sessions
                .FirstOrDefault(x => x.Id == sessionId);

            if (session == null)
                return NotFound("Session not found");

            var exercise = session.Exercises
                .FirstOrDefault(x => x.ExerciseId == exerciseId);

            if (exercise == null)
                return NotFound("Exercise not found");

            session.Exercises.Remove(exercise);

            await _repository.UpdateAsync(plan);

            return NoContent();
        }

        #endregion
    }
}
