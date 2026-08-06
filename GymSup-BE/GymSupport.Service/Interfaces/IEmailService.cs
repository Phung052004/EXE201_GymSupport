using System.Threading.Tasks;

namespace GymSupport.Service.Interfaces
{
    public interface IEmailService
    {
        Task SendEmailVerificationAsync(string email, string verificationUrl);
        Task SendPaymentReceiptAsync(string email, PaymentReceiptEmailDto receipt);
    }

    public class PaymentReceiptEmailDto
    {
        public string ReceiptNumber { get; set; } = string.Empty;
        public string CustomerName { get; set; } = string.Empty;
        public string PlanName { get; set; } = string.Empty;
        public string AmountFormatted { get; set; } = string.Empty;
        public string PaymentMethod { get; set; } = string.Empty;
        public string OrderId { get; set; } = string.Empty;
        public string TransactionId { get; set; } = string.Empty;
        public string PaidAtFormatted { get; set; } = string.Empty;
    }
}
