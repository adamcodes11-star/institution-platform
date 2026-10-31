package com.institutionplatform.controller;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.institutionplatform.model.AdminAccount;
import com.institutionplatform.model.Announcement;
import com.institutionplatform.model.AnnouncementStatus;
import com.institutionplatform.service.AdminAccountService;
import com.institutionplatform.service.AnnouncementService;

@RestController
@RequestMapping("/api/announcements")
public class AnnouncementController {

    private final AnnouncementService announcementService;
    private final AdminAccountService adminAccountService;

    public AnnouncementController(
            AnnouncementService announcementService,
            AdminAccountService adminAccountService) {
        this.announcementService = announcementService;
        this.adminAccountService = adminAccountService;
    }

    @GetMapping("/institution/{institutionId}/active")
    public List<AnnouncementResponse> getActiveAnnouncements(
            @PathVariable Long institutionId) {
        return announcementService
                .getActiveAnnouncementsForInstitution(institutionId)
                .stream().map(this::toResponse).toList();
    }

    @GetMapping("/institution/{institutionId}/display")
    public List<AnnouncementResponse> getDisplayAnnouncements(
            @PathVariable Long institutionId) {
        return announcementService
                .getActiveDisplayAnnouncementsForInstitution(institutionId)
                .stream().map(this::toResponse).toList();
    }

    @PreAuthorize("hasRole('INSTITUTION_ADMIN')")
    @GetMapping("/my")
    public List<AnnouncementResponse> getMyAnnouncements(
            Authentication authentication) {
        AdminAccount admin = getCurrentAdmin(authentication);
        if (admin.getInstitution() == null) {
            return List.of();
        }
        return announcementService
                .getAllAnnouncementsForInstitution(admin.getInstitution().getId())
                .stream().map(this::toResponse).toList();
    }

    @PreAuthorize("hasRole('SUPER_ADMIN')")
    @GetMapping
    public List<AnnouncementResponse> getAllAnnouncements() {
        return announcementService.getAllAnnouncements()
                .stream().map(this::toResponse).toList();
    }

    @PreAuthorize("hasRole('SUPER_ADMIN')")
    @GetMapping("/{id}")
    public AnnouncementResponse getAnnouncementById(@PathVariable Long id) {
        return toResponse(announcementService.getAnnouncementById(id));
    }

    @PreAuthorize("hasRole('INSTITUTION_ADMIN')")
    @PostMapping
    public AnnouncementResponse addAnnouncement(
            @RequestBody AnnouncementRequest request,
            Authentication authentication) {
        AdminAccount admin = getCurrentAdmin(authentication);
        return toResponse(announcementService.addAnnouncement(
                request.title(), request.content(), request.imageUrl(),
                request.startAt(), request.endAt(),
                request.showOnDisplayScreen(), admin));
    }

    @PreAuthorize("hasRole('INSTITUTION_ADMIN')")
    @PutMapping("/{id}")
    public AnnouncementResponse updateAnnouncement(
            @PathVariable Long id,
            @RequestBody AnnouncementRequest request,
            Authentication authentication) {
        AdminAccount admin = getCurrentAdmin(authentication);
        return toResponse(announcementService.updateAnnouncement(
                id, request.title(), request.content(), request.imageUrl(),
                request.startAt(), request.endAt(),
                request.showOnDisplayScreen(), admin));
    }

    @PreAuthorize("hasRole('INSTITUTION_ADMIN')")
    @DeleteMapping("/{id}")
    public void deleteAnnouncement(
            @PathVariable Long id,
            Authentication authentication) {
        announcementService.deleteAnnouncement(id, getCurrentAdmin(authentication));
    }

    private AdminAccount getCurrentAdmin(Authentication authentication) {
        return adminAccountService.getAdminByEmail(authentication.getName());
    }

    private AnnouncementResponse toResponse(Announcement announcement) {
        return new AnnouncementResponse(
                announcement.getId(), announcement.getTitle(),
                announcement.getContent(), announcement.getImageUrl(),
                announcement.getCreatedAt(), announcement.getStartAt(),
                announcement.getEndAt(), announcement.getStatus(),
                announcement.getInstitution().getId(),
                announcement.isShowOnDisplayScreen());
    }

    public record AnnouncementRequest(
            String title,
            String content,
            String imageUrl,
            LocalDateTime startAt,
            LocalDateTime endAt,
            boolean showOnDisplayScreen) {
    }

    public record AnnouncementResponse(
            Long id,
            String title,
            String content,
            String imageUrl,
            LocalDateTime createdAt,
            LocalDateTime startAt,
            LocalDateTime endAt,
            AnnouncementStatus status,
            Long institutionId,
            boolean showOnDisplayScreen) {
    }
}
