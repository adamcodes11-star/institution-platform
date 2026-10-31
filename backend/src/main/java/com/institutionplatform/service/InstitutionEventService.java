
package com.institutionplatform.service;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.institutionplatform.model.AdminAccount;
import com.institutionplatform.model.Institution;
import com.institutionplatform.model.InstitutionEvent;
import com.institutionplatform.repository.InstitutionEventRepository;

@Service
public class InstitutionEventService {

    private final InstitutionEventRepository eventRepository;

    public InstitutionEventService(InstitutionEventRepository eventRepository) {
        this.eventRepository = eventRepository;
    }

    // Add a new event
    public InstitutionEvent addEvent(
            String title,
            String description,
            String location,
            String imageUrl,
            LocalDateTime startAt,
            LocalDateTime endAt,
            AdminAccount createdBy) {

        validate(title, startAt, endAt);
        validateImageUrl(imageUrl);

        Institution institution = requireInstitution(createdBy);

        InstitutionEvent event = new InstitutionEvent(
                title.trim(),
                description,
                location,
                startAt,
                endAt,
                institution,
                createdBy
        );

        event.setImageUrl(normalizeImageUrl(imageUrl));

        return eventRepository.save(event);
    }

    // Public: upcoming and ongoing events
    public List<InstitutionEvent> getUpcomingEvents(Long institutionId) {
        return eventRepository
                .findByInstitutionIdAndEndAtGreaterThanEqualOrderByStartAtAsc(
                        institutionId,
                        LocalDateTime.now());
    }

    // All events for a specific institution
    public List<InstitutionEvent> getEventsForInstitution(Long institutionId) {
        return eventRepository
                .findByInstitutionIdOrderByStartAtAsc(institutionId);
    }

    // All events
    public List<InstitutionEvent> getAllEvents() {
        return eventRepository.findAll();
    }

    // Update an existing event
    public InstitutionEvent updateEvent(
            Long id,
            String title,
            String description,
            String location,
            String imageUrl,
            LocalDateTime startAt,
            LocalDateTime endAt,
            AdminAccount admin) {

        validate(title, startAt, endAt);
        validateImageUrl(imageUrl);

        Institution institution = requireInstitution(admin);

        InstitutionEvent event = eventRepository
                .findByIdAndInstitutionId(id, institution.getId())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Event not found"));

        event.setTitle(title.trim());
        event.setDescription(description);
        event.setLocation(location);
        event.setImageUrl(normalizeImageUrl(imageUrl));
        event.setStartAt(startAt);
        event.setEndAt(endAt);

        return eventRepository.save(event);
    }

    // Delete an event
    public void deleteEvent(Long id, AdminAccount admin) {

        Institution institution = requireInstitution(admin);

        InstitutionEvent event = eventRepository
                .findByIdAndInstitutionId(id, institution.getId())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Event not found"));

        eventRepository.delete(event);
    }

    // Make sure admin belongs to an institution
    private Institution requireInstitution(AdminAccount admin) {

        if (admin == null || admin.getInstitution() == null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "This account is not linked to an institution");
        }

        return admin.getInstitution();
    }

    // Validate event information
    private void validate(
            String title,
            LocalDateTime startAt,
            LocalDateTime endAt) {

        if (title == null || title.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Event title is required");
        }

        if (startAt == null
                || endAt == null
                || !startAt.isBefore(endAt)) {

            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Start time must be before end time");
        }
    }

    // Validate optional image URL
    private void validateImageUrl(String imageUrl) {

        if (imageUrl == null || imageUrl.isBlank()) {
            return;
        }

        String url = imageUrl.trim();

        if (url.length() > 2048) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Event image URL is too long");
        }

        if (!url.startsWith("https://")
                && !url.startsWith("http://")) {

            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Event image URL must start with http:// or https://");
        }
    }

    private String normalizeImageUrl(String imageUrl) {
        if (imageUrl == null || imageUrl.isBlank()) {
            return null;
        }
        return imageUrl.trim();
    }
}
