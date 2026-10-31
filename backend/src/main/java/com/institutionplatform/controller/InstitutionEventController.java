
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
import com.institutionplatform.model.EventStatus;
import com.institutionplatform.model.InstitutionEvent;
import com.institutionplatform.service.AdminAccountService;
import com.institutionplatform.service.InstitutionEventService;

@RestController
@RequestMapping("/api/events")
public class InstitutionEventController {

    private final InstitutionEventService eventService;
    private final AdminAccountService adminAccountService;

    public InstitutionEventController(
            InstitutionEventService eventService,
            AdminAccountService adminAccountService) {
        this.eventService = eventService;
        this.adminAccountService = adminAccountService;
    }

    // Public: upcoming and ongoing events
    @GetMapping("/institution/{institutionId}/upcoming")
    public List<EventResponse> getUpcomingEvents(
            @PathVariable Long institutionId) {

        return eventService.getUpcomingEvents(institutionId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // Institution Admin: own events
    @PreAuthorize("hasRole('INSTITUTION_ADMIN')")
    @GetMapping("/my")
    public List<EventResponse> getMyEvents(
            Authentication authentication) {

        AdminAccount admin = getCurrentAdmin(authentication);

        if (admin.getInstitution() == null) {
            return List.of();
        }

        return eventService
                .getEventsForInstitution(admin.getInstitution().getId())
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // Super Admin: all events
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    @GetMapping
    public List<EventResponse> getAllEvents() {

        return eventService.getAllEvents()
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // Institution Admin: add event
    @PreAuthorize("hasRole('INSTITUTION_ADMIN')")
    @PostMapping
    public EventResponse addEvent(
            @RequestBody EventRequest request,
            Authentication authentication) {

        return toResponse(eventService.addEvent(
                request.title(),
                request.description(),
                request.location(),
                request.imageUrl(),
                request.startAt(),
                request.endAt(),
                getCurrentAdmin(authentication)
        ));
    }

    // Institution Admin: update own event
    @PreAuthorize("hasRole('INSTITUTION_ADMIN')")
    @PutMapping("/{id}")
    public EventResponse updateEvent(
            @PathVariable Long id,
            @RequestBody EventRequest request,
            Authentication authentication) {

        return toResponse(eventService.updateEvent(
                id,
                request.title(),
                request.description(),
                request.location(),
                request.imageUrl(),
                request.startAt(),
                request.endAt(),
                getCurrentAdmin(authentication)
        ));
    }

    // Institution Admin: delete own event
    @PreAuthorize("hasRole('INSTITUTION_ADMIN')")
    @DeleteMapping("/{id}")
    public void deleteEvent(
            @PathVariable Long id,
            Authentication authentication) {

        eventService.deleteEvent(
                id,
                getCurrentAdmin(authentication)
        );
    }

    private AdminAccount getCurrentAdmin(
            Authentication authentication) {

        return adminAccountService.getAdminByEmail(
                authentication.getName()
        );
    }

    private EventResponse toResponse(InstitutionEvent event) {

        return new EventResponse(
                event.getId(),
                event.getTitle(),
                event.getDescription(),
                event.getLocation(),
                event.getImageUrl(),
                event.getStartAt(),
                event.getEndAt(),
                event.getCreatedAt(),
                event.getStatus(),
                event.getInstitution().getId()
        );
    }

    // Data received from Flutter
    public record EventRequest(
            String title,
            String description,
            String location,
            String imageUrl,
            LocalDateTime startAt,
            LocalDateTime endAt) {
    }

    // Data returned to Flutter
    public record EventResponse(
            Long id,
            String title,
            String description,
            String location,
            String imageUrl,
            LocalDateTime startAt,
            LocalDateTime endAt,
            LocalDateTime createdAt,
            EventStatus status,
            Long institutionId) {
    }
}
