package com.institutionplatform.service;

import org.springframework.stereotype.Service;

import com.institutionplatform.model.AdminAccount;
import com.institutionplatform.repository.AdminAccountRepository;

@Service
public class AdminAccountService {

    private final AdminAccountRepository adminAccountRepository;

    public AdminAccountService(
            AdminAccountRepository adminAccountRepository) {

        this.adminAccountRepository = adminAccountRepository;
    }

    public AdminAccount getAdminByEmail(String email) {

        return adminAccountRepository
                .findByEmail(email)
                .orElseThrow(() ->
                        new IllegalArgumentException(
                                "Admin not found"));
    }
}