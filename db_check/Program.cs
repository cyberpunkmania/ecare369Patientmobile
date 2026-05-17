using System;
using Npgsql;
using System.Data;

class Program
{
    static void Main()
    {
        string connString = "Host=dpg-d615np9r0fns73f8i1n0-a.oregon-postgres.render.com;Username=aegis369admin;Password=NyHgUJd3hJAjcjt1bpCVSjwHz35059bp;Database=aegis369db;SSL Mode=Require;Trust Server Certificate=true";

        try
        {
            using (var conn = new NpgsqlConnection(connString))
            {
                conn.Open();

                // UPDATE
                string updateSql = @"
                    UPDATE identity.""TenantPaymentMethods""
                    SET ""IsActive""=false, ""UpdatedAt""=NOW() AT TIME ZONE 'UTC'
                    WHERE ""Id"" IN ('183174f5-b436-4a11-9a81-c29676b97753','2dadd8fe-1d94-4fac-a953-e8cecc022f53')
                      AND ""TenantId""='aea82691-2558-44f1-a986-f433c0b0b3fb';";

                using (var cmd = new NpgsqlCommand(updateSql, conn))
                {
                    int affected = cmd.ExecuteNonQuery();
                    Console.WriteLine($"Rows affected: {affected}");
                }

                // SELECT
                string selectSql = @"
                    SELECT ""Id"",""IsActive"",""IsDefault"",""MpesaPaymentMode"",""MpesaPaybillNumber"",""MpesaTillNumber"",
                      LENGTH(COALESCE(""DarajaConsumerKey"",'')) AS ck_len,
                      LENGTH(COALESCE(""DarajaPassKey"",'')) AS pk_len,
                      ""IsLiveMode""
                    FROM identity.""TenantPaymentMethods""
                    WHERE ""TenantId""='aea82691-2558-44f1-a986-f433c0b0b3fb'
                    ORDER BY ""IsActive"" DESC, ""IsDefault"" DESC, ""CreatedAt"" DESC;";

                using (var cmd = new NpgsqlCommand(selectSql, conn))
                using (var reader = cmd.ExecuteReader())
                {
                    Console.WriteLine("Id | IsActive | IsDefault | MpesaPaymentMode | MpesaPaybillNumber | MpesaTillNumber | ck_len | pk_len | IsLiveMode");
                    while (reader.Read())
                    {
                        Console.WriteLine($"{reader[""Id""]} | {reader[""IsActive""]} | {reader[""IsDefault""]} | {reader[""MpesaPaymentMode""]} | {reader[""MpesaPaybillNumber""]} | {reader[""MpesaTillNumber""]} | {reader[""ck_len""]} | {reader[""pk_len""]} | {reader[""IsLiveMode""]}");
                    }
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine("Error: " + ex.Message);
        }
    }
}
