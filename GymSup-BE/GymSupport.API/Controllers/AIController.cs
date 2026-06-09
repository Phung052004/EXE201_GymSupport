using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.DTOs.AIModel;
using GymSupport.Service.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace GymSupport.API.Controllers;

[ApiController]
[Route("api/ai")]
public class AIController : ControllerBase
{
    private readonly IAIService _aiService;
    private readonly IChatRepository _chatRepository;

    public AIController(
        IAIService aiService,
        IChatRepository chatRepository)
    {
        _aiService = aiService;
        _chatRepository = chatRepository;
    }

    [HttpPost("chat")]
    public async Task<IActionResult> Chat([FromBody] ChatRequestDto dto)
    {
        try
        {
            var result = await _aiService.ChatAsync(
                dto.UserId,
                dto.Message);

            return Ok(result);
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                message = ex.Message
            });
        }
    }

    [HttpPost("apply")]
    public async Task<IActionResult> ApplySuggestions([FromBody] ApplySuggestionsRequestDto dto)
    {
        await _aiService.ApplySuggestionsAsync(dto);

        return Ok(new
        {
            success = true,
            message = "Applied successfully"
        });
    }

    [HttpGet("history/{userId}")]
    public async Task<IActionResult> GetHistory(string userId)
    {
        var messages = await _chatRepository.GetByUserIdAsync(userId);

        var result = messages.Select(x => new ChatHistoryDto
        {
            Role = x.Role,
            Content = x.Content,
            CreatedAt = x.CreatedAt
        });

        return Ok(result);
    }

    [HttpPost("analyze-image")]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> AnalyzeImage([FromForm] AnalyzeImageRequest request)
    {
        var image = request.Image;
        var mode = request.Mode;

        if (image == null || image.Length == 0)
        {
            return BadRequest(new
            {
                message = "Vui lòng chọn ảnh."
            });
        }

        var allowedTypes = new[]
        {
            "image/jpeg",
            "image/png",
            "image/webp"
        };

        if (!allowedTypes.Contains(image.ContentType))
        {
            return BadRequest(new
            {
                message = "Chỉ hỗ trợ ảnh JPG, PNG hoặc WEBP."
            });
        }

        if (image.Length > 5 * 1024 * 1024)
        {
            return BadRequest(new
            {
                message = "Ảnh không được vượt quá 5MB."
            });
        }

        // Vì form_check đã đổi sang video,
        // analyze-image chỉ nên giữ body_check và equipment_info.
        var allowedModes = new[]
        {
            "equipment_info",
            "body_check"
        };

        if (string.IsNullOrWhiteSpace(mode) || !allowedModes.Contains(mode))
        {
            return BadRequest(new
            {
                message = "Mode không hợp lệ. Dùng equipment_info hoặc body_check."
            });
        }

        await using var stream = image.OpenReadStream();

        try
        {
            var result = await _aiService.AnalyzeImageAsync(
                stream,
                image.ContentType,
                mode);

            return Ok(result);
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                message = ex.Message
            });
        }
    }

    [HttpPost("analyze-form-video")]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> AnalyzeFormVideo([FromForm] AnalyzeFormVideoRequest request)
    {
        var video = request.Video;

        if (video == null || video.Length == 0)
        {
            return BadRequest(new
            {
                message = "Vui lòng tải video lên."
            });
        }

        const long maxSize = 25 * 1024 * 1024;

        if (video.Length > maxSize)
        {
            return BadRequest(new
            {
                message = "Dung lượng video vượt quá 25MB."
            });
        }

        var allowedTypes = new[]
        {
        "video/mp4",
        "video/quicktime"
    };

        if (!allowedTypes.Contains(video.ContentType))
        {
            return BadRequest(new
            {
                message = "Chỉ hỗ trợ video MP4 hoặc MOV."
            });
        }

        try
        {
            await using var stream = video.OpenReadStream();

            var result = await _aiService.AnalyzeFormVideoAsync(
                stream,
                video.FileName,
                video.ContentType);

            return Ok(result);
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                message = ex.Message
            });
        }
    }

    public class AnalyzeImageRequest
    {
        public IFormFile? Image { get; set; }

        public string? Mode { get; set; }
    }

    public class AnalyzeFormVideoRequest
    {
        public IFormFile? Video { get; set; }
    }
}