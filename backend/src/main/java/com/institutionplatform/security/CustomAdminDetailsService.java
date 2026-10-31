package com.institutionplatform.security;

import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import com.institutionplatform.model.AdminAccount;
import com.institutionplatform.repository.AdminAccountRepository;

@Service
public class CustomAdminDetailsService implements UserDetailsService {

    private final AdminAccountRepository adminAccountRepository;

    public CustomAdminDetailsService(
            AdminAccountRepository adminAccountRepository) {

        this.adminAccountRepository = adminAccountRepository;
    }

    @Override
    public UserDetails loadUserByUsername(String email)
            throws UsernameNotFoundException {

        AdminAccount admin =
                adminAccountRepository
                        .findByEmail(email)
                        .orElseThrow(() ->
                                new UsernameNotFoundException(
                                        "Admin not found"
                                ));

        return User
                .withUsername(admin.getEmail())
                .password(admin.getPasswordHash())
                .roles(admin.getRole().name())
                .build();
    }
}