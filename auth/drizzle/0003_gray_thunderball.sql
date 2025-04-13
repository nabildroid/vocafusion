PRAGMA foreign_keys=OFF;--> statement-breakpoint
CREATE TABLE `__new_users` (
	`uid` text PRIMARY KEY NOT NULL,
	`displayName` text DEFAULT 'User' NOT NULL,
	`photoUrl` text,
	`createdAt` integer DEFAULT (CURRENT_TIMESTAMP),
	`email` text NOT NULL,
	`nativeLanguage` text DEFAULT 'English' NOT NULL,
	`claims` text
);
--> statement-breakpoint
INSERT INTO `__new_users`("uid", "displayName", "photoUrl", "createdAt", "email", "nativeLanguage", "claims") SELECT "uid", "displayName", "photoUrl", "createdAt", "email", "nativeLanguage", "claims" FROM `users`;--> statement-breakpoint
DROP TABLE `users`;--> statement-breakpoint
ALTER TABLE `__new_users` RENAME TO `users`;--> statement-breakpoint
PRAGMA foreign_keys=ON;--> statement-breakpoint
CREATE UNIQUE INDEX `users_email_unique` ON `users` (`email`);