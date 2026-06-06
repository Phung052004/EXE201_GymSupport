using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.DTOs.Customer;
using GymSupport.Repository.Models.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace GymSupport.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class CustomerController : ControllerBase
    {
        private readonly ICustomerRepository _customerRepository;
        private readonly IUserRepository _userRepository;

        public CustomerController(ICustomerRepository customerRepository, IUserRepository userRepository)
        {
            _customerRepository = customerRepository;
            _userRepository = userRepository;
        }

        [HttpGet("user/{userId}")]
        public async Task<IActionResult> GetByUserId(string userId)
        {
            var currentUser = await GetActiveUserAsync();
            if (currentUser == null)
                return Forbid();

            if (currentUser.Id != userId && currentUser.Role != "Admin")
                return Forbid();

            var customer = await _customerRepository.GetByUserIdAsync(userId);
            if (customer == null)
                return NotFound();

            return Ok(customer);
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] CreateCustomerRequest request)
        {
            var currentUser = await GetActiveUserAsync();
            if (currentUser == null)
                return Forbid();

            if (currentUser.Id != request.UserId && currentUser.Role != "Admin")
                return Forbid();

            var existing = await _customerRepository.GetByUserIdAsync(request.UserId);
            if (existing != null)
                return Conflict(new { message = "Customer record already exists for this user." });

            var customer = new Customer
            {
                UserId = request.UserId,
                Gender = request.Gender,
                Age = request.Age ?? 0,
                Bmi = request.Bmi ?? 0,
                HeightCm = request.HeightCm ?? 0,
                WeightKg = request.WeightKg ?? 0,
                Goal = request.Goal,
                ExperienceLevel = request.ExperienceLevel,
                InjuryNotes = request.InjuryNotes,
                Subscription = string.IsNullOrWhiteSpace(request.Subscription) ? "free" : request.Subscription
            };

            await _customerRepository.CreateAsync(customer);
            return CreatedAtAction(nameof(GetByUserId), new { userId = customer.UserId }, customer);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(string id, [FromBody] UpdateCustomerInfoRequest request)
        {
            var currentUser = await GetActiveUserAsync();
            if (currentUser == null)
                return Forbid();

            var customer = await _customerRepository.GetByIdAsync(id);
            if (customer == null)
                return NotFound();

            if (currentUser.Id != customer.UserId && currentUser.Role != "Admin")
                return Forbid();

            if (request.Gender != null)
                customer.Gender = request.Gender;

            if (request.Age.HasValue)
                customer.Age = request.Age.Value;

            if (request.Bmi.HasValue)
                customer.Bmi = request.Bmi.Value;

            if (request.HeightCm.HasValue)
                customer.HeightCm = request.HeightCm.Value;

            if (request.WeightKg.HasValue)
                customer.WeightKg = request.WeightKg.Value;

            if (request.Goal != null)
                customer.Goal = request.Goal;

            if (request.ExperienceLevel != null)
                customer.ExperienceLevel = request.ExperienceLevel;

            if (request.InjuryNotes != null)
                customer.InjuryNotes = request.InjuryNotes;

            if (request.Subscription != null)
                customer.Subscription = request.Subscription;

            await _customerRepository.UpdateAsync(customer);
            return NoContent();
        }

        private async Task<User?> GetActiveUserAsync()
        {
            var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub);

            if (string.IsNullOrWhiteSpace(currentUserId))
                return null;

            var currentUser = await _userRepository.GetByIdAsync(currentUserId);
            if (currentUser == null)
                return null;

            return currentUser;
        }
    }
}
