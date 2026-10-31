package com.institutionplatform.service;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.institutionplatform.model.AdminAccount;
import com.institutionplatform.model.Announcement;
import com.institutionplatform.model.Institution;
import com.institutionplatform.repository.AnnouncementRepository;

@Service
public class AnnouncementService {

    private final AnnouncementRepository announcementRepository;

    public AnnouncementService(AnnouncementRepository announcementRepository) {
        this.announcementRepository = announcementRepository;
    }

    public Announcement addAnnouncement(
            String title, String content, String imageUrl,
            LocalDateTime startAt, LocalDateTime endAt,
            boolean showOnDisplayScreen,
            AdminAccount createdBy) {
        validateAnnouncement(content, imageUrl, startAt, endAt, showOnDisplayScreen);
        Institution institution = requireInstitution(createdBy);

        Announcement announcement = new Announcement(
                title, content, imageUrl, startAt, endAt,
                showOnDisplayScreen, institution, createdBy);
        return announcementRepository.save(announcement);
    }

    public List<Announcement> getActiveAnnouncementsForInstitution(
            Long institutionId) {
        LocalDateTime now = LocalDateTime.now();
        return announcementRepository
                .findByInstitutionIdAndStartAtLessThanEqualAndEndAtGreaterThanEqual(
                        institutionId, now, now);
    }

    public List<Announcement> getActiveDisplayAnnouncementsForInstitution(
            Long institutionId) {
        return getActiveAnnouncementsForInstitution(institutionId)
                .stream()
                .filter(Announcement::isShowOnDisplayScreen)
                .filter(item -> item.getImageUrl() != null
                        && !item.getImageUrl().isBlank())
                .toList();
    }

    public List<Announcement> getAllAnnouncementsForInstitution(
            Long institutionId) {
        return announcementRepository.findByInstitutionId(institutionId);
    }

    public List<Announcement> getAllAnnouncements() {
        return announcementRepository.findAll();
    }

    public Announcement getAnnouncementById(Long id) {
        return announcementRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Announcement not found"));
    }

    public Announcement updateAnnouncement(
            Long id, String title, String content, String imageUrl,
            LocalDateTime startAt, LocalDateTime endAt,
            boolean showOnDisplayScreen,
            AdminAccount admin) {
        validateAnnouncement(content, imageUrl, startAt, endAt, showOnDisplayScreen);
        Institution institution = requireInstitution(admin);
        Announcement announcement = announcementRepository
                .findByIdAndInstitutionId(id, institution.getId())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Announcement not found"));

        announcement.setTitle(title);
        announcement.setContent(content);
        announcement.setImageUrl(imageUrl);
        announcement.setStartAt(startAt);
        announcement.setEndAt(endAt);
        announcement.setShowOnDisplayScreen(showOnDisplayScreen);
        return announcementRepository.save(announcement);
    }

    public void deleteAnnouncement(Long id, AdminAccount admin) {
        Institution institution = requireInstitution(admin);
        Announcement announcement = announcementRepository
                .findByIdAndInstitutionId(id, institution.getId())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Announcement not found"));
        announcementRepository.delete(announcement);
    }

    private Institution requireInstitution(AdminAccount admin) {
        if (admin.getInstitution() == null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "This account is not linked to an institution");
        }
        return admin.getInstitution();
    }

    private void validateAnnouncement(
            String content, String imageUrl,
            LocalDateTime startAt, LocalDateTime endAt,
            boolean showOnDisplayScreen) {
        if (startAt == null || endAt == null || startAt.isAfter(endAt)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Start time must be before end time");
        }
        if ((content == null || content.isBlank())
                && (imageUrl == null || imageUrl.isBlank())) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Announcement must contain text or image");
        }
        if (showOnDisplayScreen
                && (imageUrl == null || imageUrl.isBlank())) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "A display-screen announcement must contain an image");
        }
    }
}
