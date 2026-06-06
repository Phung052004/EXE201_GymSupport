using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.Entities;
using Microsoft.AspNetCore.Mvc;

namespace GymSupport.API.Controllers;

[ApiController]
[Route("api/muscles")]
public class MusclesController : ControllerBase
{
    private readonly IMuscleRepository _repository;

    public MusclesController(
        IMuscleRepository repository)
    {
        _repository = repository;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        return Ok(
            await _repository.GetAllAsync());
    }

    [HttpPost]
    public async Task<IActionResult> Create(
        Muscle muscle)
    {
        await _repository.CreateAsync(
            muscle);

        return Ok();
    }
}