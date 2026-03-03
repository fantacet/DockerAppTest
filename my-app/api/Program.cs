using Api.Data;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

var connStr = builder.Configuration.GetConnectionString("Default")
    ?? throw new InvalidOperationException("ConnectionStrings__Default is required.");

builder.Services.AddDbContext<AppDbContext>(opts =>
    opts.UseNpgsql(connStr));

var app = builder.Build();

// Auto-apply migrations on startup
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.Migrate();
}

var appVersion = builder.Configuration["APP_VERSION"] ?? "unknown";

var messages = new Dictionary<string, Dictionary<string, string>>
{
    ["zh-TW"] = new()
    {
        ["welcome"] = "Hello! 這是來自 Docker 的 .NET 應用。",
        ["db_stats"] = "資料庫已累計存取 {0} 次。"
    },
    ["en"] = new()
    {
        ["welcome"] = "Hello! This is a .NET app from Docker.",
        ["db_stats"] = "Database access count: {0}."
    }
};

string ResolveLang(string? lang) =>
    messages.ContainsKey(lang ?? "") ? lang! : "zh-TW";

// GET /api/health
app.MapGet("/api/health", () =>
    Results.Ok(new { status = "healthy", version = appVersion }));

// POST /api/visits
app.MapPost("/api/visits", async (HttpContext ctx, AppDbContext db) =>
{
    var lang = ResolveLang(ctx.Request.Query["lang"]);
    var visit = new Api.Models.Visit();
    db.Visits.Add(visit);
    await db.SaveChangesAsync();
    var count = await db.Visits.CountAsync();
    var msg = messages[lang];
    return Results.Ok(new
    {
        message = msg["welcome"],
        db_stats = string.Format(msg["db_stats"], count),
        count,
        version = appVersion,
        lang
    });
});

// GET /api/visits/count
app.MapGet("/api/visits/count", async (AppDbContext db) =>
{
    var count = await db.Visits.CountAsync();
    return Results.Ok(new { count });
});

app.Run();
