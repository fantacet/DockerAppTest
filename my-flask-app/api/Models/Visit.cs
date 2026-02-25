namespace Api.Models;

public class Visit
{
    public int Id { get; set; }
    public DateTime Ts { get; set; } = DateTime.UtcNow;
}
