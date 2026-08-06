using GymSupport.Repository.Models.Entities;

namespace GymSupport.Repository.Interfaces;

public interface IReceiptRepository
{
    Task CreateAsync(Receipt receipt);
    Task UpdateAsync(Receipt receipt);
    Task<Receipt?> GetByPaymentIdAsync(string paymentId);
    Task<List<Receipt>> GetByUserIdAsync(string userId);
    Task<List<Receipt>> GetAllAsync();
    Task<long> CountAsync();
}
