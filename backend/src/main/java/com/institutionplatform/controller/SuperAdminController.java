package com.institutionplatform.controller;

import java.util.List;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.institutionplatform.model.AdminAccount;
import com.institutionplatform.model.AdminRole;
import com.institutionplatform.model.Institution;
import com.institutionplatform.service.InstitutionService;
import com.institutionplatform.service.SuperAdminService;

@RestController
@RequestMapping("/api/super-admin")
@PreAuthorize("hasRole('SUPER_ADMIN')")
public class SuperAdminController {

    private final SuperAdminService superAdminService;
    private final InstitutionService institutionService;

    public SuperAdminController(
            SuperAdminService superAdminService,
            InstitutionService institutionService) {
        this.superAdminService = superAdminService;
        this.institutionService = institutionService;
    }

    @PostMapping("/institution-admins")
    public AdminAccountResponse addInstitutionAdmin(
            @RequestBody CreateInstitutionAdminRequest request) {
        Institution institution = institutionService
                .getInstitutionById(request.institutionId());
        AdminAccount admin = superAdminService.addInstitutionAdmin(
                request.name(), request.email(), request.password(), institution);
        return toResponse(admin);
    }

    @GetMapping("/admins")
    public List<AdminAccountResponse> getAllAdmins() {
        return superAdminService.getAllAdmins()
                .stream().map(this::toResponse).toList();
    }

    @GetMapping("/admins/{id}")
    public AdminAccountResponse getAdminById(@PathVariable Long id) {
        return toResponse(superAdminService.getAdminById(id));
    }

    @DeleteMapping("/admins/{id}")
    public void deleteAdmin(@PathVariable Long id) {
        superAdminService.deleteAdmin(id);
    }

    private AdminAccountResponse toResponse(AdminAccount admin) {
        Long institutionId = admin.getInstitution() == null
                ? null : admin.getInstitution().getId();
        return new AdminAccountResponse(
                admin.getId(), admin.getName(), admin.getEmail(),
                admin.getRole(), institutionId);
    }

    public record CreateInstitutionAdminRequest(
            String name,
            String email,
            String password,
            Long institutionId) {
    }

    public record AdminAccountResponse(
            Long id,
            String name,
            String email,
            AdminRole role,
            Long institutionId) {
    }
}
