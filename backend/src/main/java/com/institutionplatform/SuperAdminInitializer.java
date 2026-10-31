package com.institutionplatform;

import com.institutionplatform.model.AdminAccount;
import com.institutionplatform.model.AdminRole;
import com.institutionplatform.repository.AdminAccountRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
@Profile("!demo")
public class SuperAdminInitializer {
    @Bean
    CommandLineRunner createSuperAdmin(AdminAccountRepository repository,
                                        PasswordEncoder passwordEncoder) {
        return args -> {
            // Optional first-run bootstrap. Never store admin credentials in source code.
            String email = System.getenv("SUPER_ADMIN_EMAIL");
            String password = System.getenv("SUPER_ADMIN_PASSWORD");
            if (email == null || email.isBlank() || password == null || password.isBlank()) {
                return;
            }
            email = email.trim().toLowerCase(java.util.Locale.ROOT);
            if (repository.existsByEmail(email)) {
                return; // Do not overwrite an existing administrator.
            }
            AdminAccount admin = new AdminAccount(
                    "Platform Admin", email, passwordEncoder.encode(password),
                    AdminRole.SUPER_ADMIN, null);
            repository.save(admin);
        };
    }
}
