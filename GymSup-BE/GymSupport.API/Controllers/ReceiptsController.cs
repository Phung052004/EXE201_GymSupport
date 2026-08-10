using GymSupport.Repository.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GymSupport.API.Controllers;

[ApiController]
[Route("api/admin/receipts")]
[Authorize(Roles = "Admin,Manager")]
public class ReceiptsController : ControllerBase
{
    private readonly IReceiptRepository _receipts;

    public ReceiptsController(IReceiptRepository receipts)
    {
        _receipts = receipts;
    }

    /// <summary>
    /// Danh sách user từng có receipt (đã thanh toán thành công ≥1 lần). Name/Email lấy từ
    /// snapshot lưu tại thời điểm thanh toán gần nhất — không join bảng User để giữ đúng thông
    /// tin định danh lúc giao dịch, kể cả nếu user đổi email sau này.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetUsersWithReceipts()
    {
        var all = await _receipts.GetAllAsync();

        var grouped = all
            .GroupBy(r => r.UserId)
            .Select(g =>
            {
                var latest = g.OrderByDescending(r => r.CreatedAt).First();
                return new
                {
                    userId = g.Key,
                    name = latest.CustomerName,
                    email = latest.CustomerEmail,
                    receiptCount = g.Count()
                };
            })
            .OrderByDescending(x => x.receiptCount)
            .ToList();

        return Ok(grouped);
    }

    /// <summary>Tất cả receipt của 1 user — dùng cho nút Action ở tab Receipts lẫn User Detail.</summary>
    [HttpGet("user/{userId}")]
    public async Task<IActionResult> GetByUser(string userId)
    {
        var receipts = await _receipts.GetByUserIdAsync(userId);
        return Ok(receipts.OrderByDescending(r => r.CreatedAt));
    }
}
