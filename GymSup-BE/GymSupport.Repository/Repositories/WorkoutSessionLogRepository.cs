using GymCoach.Api.Config;
using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.Entities;
using MongoDB.Driver;

namespace GymSupport.Repository.Repositories;

public class WorkoutSessionLogRepository : IWorkoutSessionLogRepository
{
    private readonly IMongoCollection<WorkoutSessionLog> _collection;

    public WorkoutSessionLogRepository(MongoDbContext context)
    {
        _collection = context.GetCollection<WorkoutSessionLog>("WorkoutSessionLogs");

        var userIdIndex = Builders<WorkoutSessionLog>.IndexKeys.Ascending(x => x.UserId);
        var startTimeIndex = Builders<WorkoutSessionLog>.IndexKeys.Ascending(x => x.StartTime);
        _collection.Indexes.CreateOne(new CreateIndexModel<WorkoutSessionLog>(userIdIndex));
        _collection.Indexes.CreateOne(new CreateIndexModel<WorkoutSessionLog>(startTimeIndex));
    }

    public async Task<WorkoutSessionLog> CreateAsync(WorkoutSessionLog sessionLog)
    {
        await _collection.InsertOneAsync(sessionLog);
        return sessionLog;
    }

    public async Task<WorkoutSessionLog?> GetByIdAsync(string id)
    {
        return await _collection
            .Find(x => x.Id == id)
            .FirstOrDefaultAsync();
    }

    public async Task<WorkoutSessionLog?> GetActiveByUserIdAsync(string userId)
    {
        return await _collection
            .Find(x =>
                x.UserId == userId &&
                (x.Status == "IN_PROGRESS" || x.Status == "PAUSED"))
            .FirstOrDefaultAsync();
    }

    public async Task<List<WorkoutSessionLog>> GetByUserIdAsync(string userId)
    {
        return await _collection
            .Find(x => x.UserId == userId)
            .SortByDescending(x => x.StartTime)
            .ToListAsync();
    }

    public async Task<List<WorkoutSessionLog>> GetByUserIdsAsync(IEnumerable<string> userIds)
    {
        var filter = Builders<WorkoutSessionLog>.Filter.In(x => x.UserId, userIds);
        return await _collection.Find(filter).ToListAsync();
    }

    public async Task UpdateAsync(string id, WorkoutSessionLog sessionLog)
    {
        await _collection.ReplaceOneAsync(
            x => x.Id == id,
            sessionLog);
    }

    public async Task<List<WorkoutSessionLog>> GetAllAsync()
    {
        return await _collection
            .Find(_ => true)
            .ToListAsync();
    }

    public async Task<List<WorkoutSessionLog>> GetByDateRangeAsync(DateTime from, DateTime to)
    {
        return await _collection
            .Find(x => x.StartTime >= from && x.StartTime < to)
            .SortBy(x => x.StartTime)
            .ToListAsync();
    }

    public async Task<long> CountCompletedAsync()
    {
        return await _collection.CountDocumentsAsync(x => x.EndTime != null);
    }
}
