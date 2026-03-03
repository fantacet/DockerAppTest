using Microsoft.EntityFrameworkCore;
using Api.Models;

namespace Api.Data;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<Visit> Visits => Set<Visit>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Visit>(e =>
        {
            e.ToTable("visits");
            e.HasKey(v => v.Id);
            e.Property(v => v.Id).HasColumnName("id").UseIdentityAlwaysColumn();
            e.Property(v => v.Ts).HasColumnName("ts").HasDefaultValueSql("CURRENT_TIMESTAMP");
        });
    }
}
