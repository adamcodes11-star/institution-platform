package com.institutionplatform.controller;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import com.institutionplatform.model.AdminAccount;
import com.institutionplatform.repository.AdminAccountRepository;

import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AdminAccountRepository adminAccountRepository;

    public AuthController(
            AdminAccountRepository adminAccountRepository
    ) {
        this.adminAccountRepository = adminAccountRepository;
    }

    @GetMapping("/me")
    public Map<String, Object> getCurrentAdmin(
            Authentication authentication
    ) {
        AdminAccount account = adminAccountRepository
                .findByEmail(authentication.getName())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "Admin account not found"
                ));

        Map<String, Object> response = new LinkedHashMap<>();

        response.put("id", account.getId());
        response.put("name", account.getName());
        response.put("email", account.getEmail());
        response.put("role", account.getRole().name());

        if (account.getInstitution() == null) {
            response.put("institutionId", null);
            response.put("institutionName", null);
        } else {
            response.put("institutionId", account.getInstitution().getId());
            response.put("institutionName", account.getInstitution().getName());
        }

        return response;
    }
}
