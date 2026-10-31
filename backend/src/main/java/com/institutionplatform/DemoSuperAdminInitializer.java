package com.institutionplatform;

import com.institutionplatform.model.AdminAccount;
import com.institutionplatform.model.AdminRole;
import com.institutionplatform.repository.AdminAccountRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;

/** Public test login, ONLY for a local demo database; never deploy publicly. */
@Configuration
@Profile("demo")
public class DemoSuperAdminInitializer {
    private static final String DEMO_EMAIL = "demo.superadmin@example.com";
    private static final String DEMO_PASSWORD = "DemoAdmin2026!";

    @Bean
    CommandLineRunner createDemoSuperAdmin(AdminAccountRepository repository,
                                            PasswordEncoder passwordEncoder,
                                            @Value("${spring.datasource.url}") String databaseUrl) {
        return args -> {
            DemoSafety.requireLocalDemoDatabase(databaseUrl);
            if (repository.existsByEmail(DEMO_EMAIL)) {
                System.out.println("[Demo] Demo super administrator already exists.");
                return;
            }
            AdminAccount demoAdmin = new AdminAccount(
                    "Demo Super Administrator", DEMO_EMAIL,
                    passwordEncoder.encode(DEMO_PASSWORD),
                    AdminRole.SUPER_ADMIN, null);
            repository.save(demoAdmin);
            System.out.println("[Demo] Created demo super administrator for local testing only.");
        };
    }
}
