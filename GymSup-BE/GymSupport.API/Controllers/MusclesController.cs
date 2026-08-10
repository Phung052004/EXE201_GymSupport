using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.Entities;
using Microsoft.AspNetCore.Mvc;

namespace GymSupport.API.Controllers;

[ApiController]
[Route("api/muscles")]
public class MusclesController : ControllerBase
{
    private readonly IMuscleRepository _repository;

    public MusclesController(IMuscleRepository repository)
    {
        _repository = repository;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var muscles = await _repository.GetAllAsync();

        return Ok(muscles);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(string id)
    {
        var muscle = await _repository.GetByIdAsync(id);

        if (muscle == null)
            return NotFound("Không tìm thấy nhóm cơ");

        return Ok(muscle);
    }

    [HttpGet("category/{category}")]
    public async Task<IActionResult> GetByCategory(string category)
    {
        var muscles = await _repository.GetByCategoryAsync(category);

        return Ok(muscles);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] Muscle muscle)
    {
        if (string.IsNullOrWhiteSpace(muscle.Name))
            return BadRequest("Tên nhóm cơ là bắt buộc");

        if (string.IsNullOrWhiteSpace(muscle.Category))
            return BadRequest("Danh mục nhóm cơ là bắt buộc");

        await _repository.CreateAsync(muscle);

        return Ok(muscle);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(string id, [FromBody] Muscle request)
    {
        var muscle = await _repository.GetByIdAsync(id);

        if (muscle == null)
            return NotFound("Không tìm thấy nhóm cơ");

        muscle.Name = request.Name;
        muscle.Category = request.Category;

        await _repository.UpdateAsync(muscle);

        return Ok(muscle);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(string id)
    {
        var muscle = await _repository.GetByIdAsync(id);

        if (muscle == null)
            return NotFound("Không tìm thấy nhóm cơ");

        await _repository.DeleteAsync(id);

        return NoContent();
    }


    [HttpGet("by-category")]
    public async Task<IActionResult> GetByCategoryQuery([FromQuery] string category)
    {
        if (string.IsNullOrWhiteSpace(category))
            return BadRequest("Danh mục là bắt buộc");

        var muscles = await _repository.GetByCategoryAsync(category);

        return Ok(muscles);
    }

    [HttpGet("categories")]
    public async Task<IActionResult> GetCategories()
    {
        var muscles = await _repository.GetAllAsync();

        var categories = muscles
            .Where(x => !string.IsNullOrWhiteSpace(x.Category))
            .Select(x => x.Category.Trim())
            .Distinct()
            .OrderBy(x => x)
            .ToList();

        return Ok(categories);
    }
}