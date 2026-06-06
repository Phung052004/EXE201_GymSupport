using GymCoach.Api.Config;
using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.Entities;
using MongoDB.Driver;

namespace GymSupport.Repository.Repositories;

public class MuscleRepository : IMuscleRepository
{
    private readonly IMongoCollection<Muscle> _collection;

    public MuscleRepository(
        MongoDbContext context)
    {
        _collection =
            context.GetCollection<Muscle>(
                "Muscles");
    }

    public async Task<List<Muscle>> GetAllAsync()
    {
        return await _collection
            .Find(_ => true)
            .ToListAsync();
    }

    public async Task<Muscle?> GetByIdAsync(
        string id)
    {
        return await _collection
            .Find(x => x.Id == id)
            .FirstOrDefaultAsync();
    }

    public async Task CreateAsync(
        Muscle muscle)
    {
        await _collection
            .InsertOneAsync(muscle);
    }

    public async Task UpdateAsync(
        Muscle muscle)
    {
        await _collection.ReplaceOneAsync(
            x => x.Id == muscle.Id,
            muscle);
    }

    public async Task DeleteAsync(
        string id)
    {
        await _collection.DeleteOneAsync(
            x => x.Id == id);
    }
}