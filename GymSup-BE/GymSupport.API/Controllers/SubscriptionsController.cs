using GymSupport.Service.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace GymSupport.API.Controllers;

[ApiController]
[Route("api/subscriptions")]
[Authorize]
public class SubscriptionsController : ControllerBase
{
    private readonly ISubscriptionService _subscriptionService;

    public SubscriptionsController(ISubscriptionService subscriptionService)
    {
        _subscriptionService = subscriptionService;
    }

    /// <summary>
    /// Get all available subscription plans
    /// </summary>
    [HttpGet("plans")]
    [AllowAnonymous]
    public async Task<IActionResult> GetAllPlans()
    {
        try
        {
            var plans = await _subscriptionService.GetAllSubscriptionPlansAsync();
            return Ok(plans);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Lỗi khi lấy danh sách gói đăng ký", error = ex.Message });
        }
    }

    /// <summary>
    /// Get active subscription plans only
    /// </summary>
    [HttpGet("plans/active")]
    [AllowAnonymous]
    public async Task<IActionResult> GetActivePlans()
    {
        try
        {
            var plans = await _subscriptionService.GetActiveSubscriptionPlansAsync();
            return Ok(plans);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Lỗi khi lấy danh sách gói đăng ký đang hoạt động", error = ex.Message });
        }
    }

    /// <summary>
    /// Get a specific subscription plan by ID
    /// </summary>
    [HttpGet("plans/{id}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetPlanById(string id)
    {
        try
        {
            var plan = await _subscriptionService.GetSubscriptionPlanAsync(id);
            if (plan == null)
                return NotFound(new { message = "Không tìm thấy gói đăng ký" });

            return Ok(plan);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Lỗi khi lấy gói đăng ký", error = ex.Message });
        }
    }

    /// <summary>
    /// Create a new subscription plan (Admin only)
    /// </summary>
    [HttpPost("plans")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> CreatePlan([FromBody] CreateSubscriptionPlanDto dto)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(dto.Name))
                return BadRequest(new { message = "Tên gói đăng ký là bắt buộc" });

            if (dto.DurationMonths <= 0)
                return BadRequest(new { message = "Thời hạn phải lớn hơn 0" });

            if (dto.Price < 0)
                return BadRequest(new { message = "Giá không được là số âm" });

            await _subscriptionService.CreateSubscriptionPlanAsync(dto);
            return Created("", new { message = "Tạo gói đăng ký thành công" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Lỗi khi tạo gói đăng ký", error = ex.Message });
        }
    }

    /// <summary>
    /// Update subscription plan status (activate/deactivate)
    /// </summary>
    [HttpPatch("plans/{id}/status")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdatePlanStatus(string id, [FromBody] UpdatePlanStatusDto dto)
    {
        try
        {
            await _subscriptionService.UpdateSubscriptionPlanAsync(id, dto.IsActive);
            var status = dto.IsActive ? "kích hoạt" : "vô hiệu hóa";
            return Ok(new { message = $"Đã {status} gói đăng ký thành công" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Lỗi khi cập nhật gói đăng ký", error = ex.Message });
        }
    }

    /// <summary>
    /// Update subscription plan details (Full Update)
    /// </summary>
    [HttpPut("plans/{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdatePlan(string id, [FromBody] UpdateSubscriptionPlanDto dto)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(dto.Name))
                return BadRequest(new { message = "Tên gói đăng ký là bắt buộc" });

            if (dto.DurationMonths <= 0)
                return BadRequest(new { message = "Thời hạn phải lớn hơn 0" });

            if (dto.Price < 0)
                return BadRequest(new { message = "Giá không được là số âm" });

            await _subscriptionService.UpdateSubscriptionPlanFullAsync(id, dto);
            return Ok(new { message = "Cập nhật gói đăng ký thành công" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Lỗi khi cập nhật gói đăng ký", error = ex.Message });
        }
    }

    /// <summary>
    /// Delete a subscription plan (Admin only)
    /// </summary>
    [HttpDelete("plans/{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DeletePlan(string id)
    {
        try
        {
            var plan = await _subscriptionService.GetSubscriptionPlanAsync(id);
            if (plan == null)
                return NotFound(new { message = "Không tìm thấy gói đăng ký" });

            await _subscriptionService.DeleteSubscriptionPlanAsync(id);
            return Ok(new { message = "Xóa gói đăng ký thành công" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Lỗi khi xóa gói đăng ký", error = ex.Message });
        }
    }

    /// <summary>
    /// Get all user subscriptions (Admin only)
    /// </summary>
    [HttpGet("admin/all")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAllUserSubscriptions()
    {
        try
        {
            var subs = await _subscriptionService.GetAllUserSubscriptionsAsync();
            return Ok(subs);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Lỗi khi lấy danh sách đăng ký của người dùng", error = ex.Message });
        }
    }

    /// <summary>
    /// Get current subscription of authenticated user
    /// Response: { "planName", "startDate", "endDate", "daysRemaining", "status" }
    /// </summary>
    [HttpGet("me")]
    public async Task<IActionResult> GetMySubscription()
    {
        try
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub);

            if (string.IsNullOrWhiteSpace(userId))
                return Unauthorized(new { message = "Không tìm thấy User ID trong token" });

            var subscription = await _subscriptionService.GetUserCurrentSubscriptionAsync(userId);
            if (subscription == null)
                return Ok(new { message = "Không có gói đăng ký nào đang hoạt động" });

            return Ok(subscription);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Lỗi khi lấy gói đăng ký của người dùng", error = ex.Message });
        }
    }

    /// <summary>
    /// Cancel user's current subscription
    /// </summary>
    [HttpPut("me/cancel")]
    public async Task<IActionResult> CancelSubscription()
    {
        try
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub);

            if (string.IsNullOrWhiteSpace(userId))
                return Unauthorized(new { message = "Không tìm thấy User ID trong token" });

            await _subscriptionService.CancelUserSubscriptionAsync(userId);
            return Ok(new { message = "Hủy gói đăng ký thành công" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Lỗi khi hủy gói đăng ký", error = ex.Message });
        }
    }
}

/// <summary>
/// Update subscription plan status DTO
/// </summary>
public class UpdatePlanStatusDto
{
    public bool IsActive { get; set; }
}
