package com.institutionplatform.service;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.institutionplatform.model.AdminAccount;
import com.institutionplatform.model.AdminRole;
import com.institutionplatform.model.Institution;
import com.institutionplatform.repository.AdminAccountRepository;
import com.institutionplatform.repository.AnnouncementRepository;
import com.institutionplatform.repository.InstitutionEventRepository;

@Service
public class SuperAdminService {

    private final AdminAccountRepository adminAccountRepository;
    private final AnnouncementRepository announcementRepository;
    private final InstitutionEventRepository eventRepository;
    private final PasswordEncoder passwordEncoder;

    public SuperAdminService(
            AdminAccountRepository adminAccountRepository,
            AnnouncementRepository announcementRepository,
            InstitutionEventRepository eventRepository,
            PasswordEncoder passwordEncoder) {
        this.adminAccountRepository = adminAccountRepository;
        this.announcementRepository = announcementRepository;
        this.eventRepository = eventRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public AdminAccount addInstitutionAdmin(
            String name, String email, String rawPassword,
            Institution institution) {
        if (name == null || name.isBlank()
                || email == null || email.isBlank()
                || rawPassword == null || rawPassword.length() < 6) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Name, email and a password of at least 6 characters are required");
        }

        String normalizedEmail = email.trim().toLowerCase();
        if (adminAccountRepository.existsByEmail(normalizedEmail)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "An account with this email already exists");
        }
        if (adminAccountRepository.existsByInstitutionId(institution.getId())) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "This institution already has an admin account");
        }

        AdminAccount admin = new AdminAccount(
                name.trim(), normalizedEmail,
                passwordEncoder.encode(rawPassword),
                AdminRole.INSTITUTION_ADMIN,
                institution);
        return adminAccountRepository.save(admin);
    }

    public List<AdminAccount> getAllAdmins() {
        return adminAccountRepository.findAll();
    }

    public AdminAccount getAdminById(Long id) {
        return adminAccountRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Admin not found"));
    }

    public void deleteAdmin(Long id) {
        AdminAccount account = getAdminById(id);
        if (account.getRole() == AdminRole.SUPER_ADMIN) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Super admin accounts cannot be deleted here");
        }
        if (announcementRepository.existsByCreatedById(id)
                || eventRepository.existsByCreatedById(id)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "This admin created content and cannot be deleted");
        }
        adminAccountRepository.delete(account);
    }
}
