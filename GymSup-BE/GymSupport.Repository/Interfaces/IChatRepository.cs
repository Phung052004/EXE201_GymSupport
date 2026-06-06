using GymSupport.Repository.Models.Entities;

namespace GymSupport.Repository.Interfaces;

public interface IChatRepository
{
    Task CreateAsync(ChatMessage message);

    Task<List<ChatMessage>> GetRecentMessagesAsync(
        string userId,
        int count = 20);

    Task<List<ChatMessage>> GetByUserIdAsync(
    string userId);
}