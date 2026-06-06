using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.DTOs.Exercise;
using GymSupport.Repository.Models.Entities;
using Microsoft.AspNetCore.Mvc;

namespace GymSupport.API.Controllers;

[ApiController]
[Route("api/exercises")]
public class ExercisesController : ControllerBase
{
    private readonly IExerciseRepository _repository;

    public ExercisesController(
        IExerciseRepository repository)
    {
        _repository = repository;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var exercises =
            await _repository.GetAllAsync();

        return Ok(exercises);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(
        string id)
    {
        var exercise =
            await _repository.GetByIdAsync(id);

        if (exercise == null)
            return NotFound();

        return Ok(exercise);
    }

    [HttpPost]
    public async Task<IActionResult> Create(
        CreateExerciseDto dto)
    {
        var exercise =
            new Exercise
            {
                Name = dto.Name,
                Equipment = dto.Equipment,
                Difficulty = dto.Difficulty,
                ImageUrl = dto.ImageUrl,
                VideoUrl = dto.VideoUrl,

                MuscleImpacts =
                    dto.MuscleImpacts
                        .Select(x =>
                            new MuscleImpact
                            {
                                MuscleId =
                                    x.MuscleId,

                                Percentage =
                                    x.Percentage
                            })
                        .ToList()
            };

        await _repository.CreateAsync(
            exercise);

        return Ok(exercise);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(
        string id,
        CreateExerciseDto dto)
    {
        var exercise =
            await _repository.GetByIdAsync(id);

        if (exercise == null)
            return NotFound();

        exercise.Name = dto.Name;
        exercise.Equipment = dto.Equipment;
        exercise.Difficulty = dto.Difficulty;
        exercise.ImageUrl = dto.ImageUrl;
        exercise.VideoUrl = dto.VideoUrl;

        exercise.MuscleImpacts =
            dto.MuscleImpacts
                .Select(x =>
                    new MuscleImpact
                    {
                        MuscleId =
                            x.MuscleId,

                        Percentage =
                            x.Percentage
                    })
                .ToList();

        await _repository.UpdateAsync(
            exercise);

        return Ok(exercise);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(
        string id)
    {
        var exercise =
            await _repository.GetByIdAsync(id);

        if (exercise == null)
            return NotFound();

        await _repository.DeleteAsync(id);

        return NoContent();
    }
}