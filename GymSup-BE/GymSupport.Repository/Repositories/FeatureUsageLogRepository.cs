using GymCoach.Api.Config;
using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.Entities;
using MongoDB.Driver;

namespace GymSupport.Repository.Repositories;

public class FeatureUsageLogRepository : IFeatureUsageLogRepository
{
    private readonly IMongoCollection<FeatureUsageLog> _collection;

    public FeatureUsageLogRepository(MongoDbContext context)
    {
        _collection = context.GetCollection<FeatureUsageLog>("FeatureUsageLogs");

        var userIdIndex = Builders<FeatureUsageLog>.IndexKeys.Ascending(x => x.UserId);
        var featureIndex = Builders<FeatureUsageLog>.IndexKeys.Ascending(x => x.Feature);
        var createdAtIndex = Builders<FeatureUsageLog>.IndexKeys.Ascending(x => x.CreatedAt);

        _collection.Indexes.CreateOne(new CreateIndexModel<FeatureUsageLog>(userIdIndex));
        _collection.Indexes.CreateOne(new CreateIndexModel<FeatureUsageLog>(featureIndex));
        _collection.Indexes.CreateOne(new CreateIndexModel<FeatureUsageLog>(createdAtIndex));
    }

    public Task CreateAsync(FeatureUsageLog log) =>
        _collection.InsertOneAsync(log);

    public async Task<List<FeatureUsageLog>> GetByDateRangeAsync(DateTime from, DateTime to) =>
        await _collection.Find(x => x.CreatedAt >= from && x.CreatedAt < to).ToListAsync();

    public async Task<List<FeatureUsageLog>> GetAllAsync() =>
        await _collection.Find(_ => true).ToListAsync();
}
