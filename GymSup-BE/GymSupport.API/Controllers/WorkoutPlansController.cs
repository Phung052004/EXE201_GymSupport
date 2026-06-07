using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.Entities;
using Microsoft.AspNetCore.Mvc;

namespace GymSupport.API.Controllers;

[ApiController]
[Route("api/workoutplans")]
public class WorkoutPlansController : ControllerBase
{
    private readonly IWorkoutPlanRepository _repository;

    public WorkoutPlansController(IWorkoutPlanRepository repository)
    {
        _repository = repository;
    }

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

    [HttpGet("user/{userId}/active")]
    public async Task<IActionResult> GetActiveByUser(string userId)
    {
        var plan = await _repository.GetActiveByUserIdAsync(userId);

        if (plan == null)
            return NotFound("No active workout plan found");

        return Ok(plan);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] WorkoutPlan plan)
    {
        await _repository.DeactivateAllByUserIdAsync(plan.UserId);

        plan.IsActive = true;

        await _repository.CreateAsync(plan);

        return Ok(plan);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(string id, [FromBody] WorkoutPlan request)
    {
        var plan = await _repository.GetByIdAsync(id);

        if (plan == null)
            return NotFound("Workout plan not found");

        request.Id = id;

        await _repository.UpdateAsync(request);

        return Ok(request);
    }

    [HttpPut("{id}/activate")]
    public async Task<IActionResult> Activate(string id)
    {
        var plan = await _repository.GetByIdAsync(id);

        if (plan == null)
            return NotFound("Workout plan not found");

        await _repository.DeactivateAllByUserIdAsync(plan.UserId);

        plan.IsActive = true;

        await _repository.UpdateAsync(plan);

        return Ok(plan);
    }

    [HttpPut("{id}/deactivate")]
    public async Task<IActionResult> Deactivate(string id)
    {
        var plan = await _repository.GetByIdAsync(id);

        if (plan == null)
            return NotFound("Workout plan not found");

        plan.IsActive = false;

        await _repository.UpdateAsync(plan);

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
}