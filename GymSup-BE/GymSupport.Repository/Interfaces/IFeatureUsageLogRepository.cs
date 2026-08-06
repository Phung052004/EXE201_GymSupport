using GymSupport.Repository.Models.Entities;

namespace GymSupport.Repository.Interfaces;

public interface IFeatureUsageLogRepository
{
    Task CreateAsync(FeatureUsageLog log);
    Task<List<FeatureUsageLog>> GetByDateRangeAsync(DateTime from, DateTime to);
    Task<List<FeatureUsageLog>> GetAllAsync();
}
