import { sql } from "drizzle-orm";
import { SQLiteBlobJson, integer, sqliteTable, text, type AnySQLiteColumn } from "drizzle-orm/sqlite-core";


export const usersTable = sqliteTable("users", {
    uid: text("uid").notNull().primaryKey(),
    displayName: text().notNull().default("User"),
    photoUrl: text(),
    createdAt: integer({ mode: 'timestamp_ms' }).default(sql`(CURRENT_TIMESTAMP)`),
    email: text().notNull().unique(),
    nativeLanguage: text().default("English").notNull(),
    claims: text({ mode: 'json' }).$type<{
        premiumExpires?: number,
    }>()
}); 