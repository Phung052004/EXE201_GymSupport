using GymCoach.Api.Config;
using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.Entities;
using MongoDB.Driver;

namespace GymSupport.Repository.Repositories;

public class ReceiptRepository : IReceiptRepository
{
    private readonly IMongoCollection<Receipt> _collection;

    public ReceiptRepository(MongoDbContext context)
    {
        _collection = context.GetCollection<Receipt>("Receipts");

        var userIdIndex = Builders<Receipt>.IndexKeys.Ascending(x => x.UserId);
        var paymentIdIndex = Builders<Receipt>.IndexKeys.Ascending(x => x.PaymentId);
        var createdAtIndex = Builders<Receipt>.IndexKeys.Ascending(x => x.CreatedAt);

        _collection.Indexes.CreateOne(new CreateIndexModel<Receipt>(userIdIndex));
        _collection.Indexes.CreateOne(new CreateIndexModel<Receipt>(
            paymentIdIndex,
            new CreateIndexOptions { Unique = true, Sparse = true }));
        _collection.Indexes.CreateOne(new CreateIndexModel<Receipt>(createdAtIndex));
    }

    public Task CreateAsync(Receipt receipt) =>
        _collection.InsertOneAsync(receipt);

    public Task UpdateAsync(Receipt receipt) =>
        _collection.ReplaceOneAsync(x => x.Id == receipt.Id, receipt);

    public async Task<Receipt?> GetByPaymentIdAsync(string paymentId) =>
        await _collection.Find(x => x.PaymentId == paymentId).FirstOrDefaultAsync();

    public async Task<List<Receipt>> GetByUserIdAsync(string userId) =>
        await _collection.Find(x => x.UserId == userId).SortByDescending(x => x.CreatedAt).ToListAsync();

    public async Task<List<Receipt>> GetAllAsync() =>
        await _collection.Find(_ => true).SortByDescending(x => x.CreatedAt).ToListAsync();

    public async Task<long> CountAsync() =>
        await _collection.CountDocumentsAsync(_ => true);
}
