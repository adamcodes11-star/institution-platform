
package com.institutionplatform.service;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.institutionplatform.model.AdminAccount;
import com.institutionplatform.model.AdminRole;
import com.institutionplatform.model.Institution;
import com.institutionplatform.repository.AdminAccountRepository;
import com.institutionplatform.repository.AnnouncementRepository;
import com.institutionplatform.repository.InstitutionEventRepository;
import com.institutionplatform.repository.InstitutionRepository;

@Service
public class InstitutionService {

    private final InstitutionRepository institutionRepository;
    private final AdminAccountRepository adminAccountRepository;
    private final AnnouncementRepository announcementRepository;
    private final InstitutionEventRepository eventRepository;

    public InstitutionService(
            InstitutionRepository institutionRepository,
            AdminAccountRepository adminAccountRepository,
            AnnouncementRepository announcementRepository,
            InstitutionEventRepository eventRepository) {

        this.institutionRepository = institutionRepository;
        this.adminAccountRepository = adminAccountRepository;
        this.announcementRepository = announcementRepository;
        this.eventRepository = eventRepository;
    }

    public Institution addInstitution(Institution institution) {
        validate(institution);
        return institutionRepository.save(institution);
    }

    public List<Institution> getAllInstitutions() {
        return institutionRepository.findAll();
    }

    public Institution getInstitutionById(Long id) {
        return institutionRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Institution not found"));
    }

    // Search by name, city and type together
    public List<Institution> searchInstitutions(
            String name, String city, String type) {

        String normalizedName = name == null
                ? "" : name.trim().toLowerCase();

        String normalizedCity = city == null
                ? "" : city.trim().toLowerCase();

        String normalizedType = type == null
                ? "" : type.trim().toLowerCase();

        return institutionRepository.findAll()
                .stream()
                .filter(institution ->
                        normalizedName.isEmpty()
                        || (institution.getName() != null
                        && institution.getName().toLowerCase()
                                .contains(normalizedName)))
                .filter(institution ->
                        normalizedCity.isEmpty()
                        || (institution.getCity() != null
                        && institution.getCity().toLowerCase()
                                .contains(normalizedCity)))
                .filter(institution ->
                        normalizedType.isEmpty()
                        || (institution.getType() != null
                        && institution.getType().toLowerCase()
                                .contains(normalizedType)))
                .toList();
    }

    // Update institution information
    public Institution updateInstitution(
            Long id,
            Institution update) {

        validate(update);

        Institution institution = getInstitutionById(id);

        institution.setName(update.getName());
        institution.setCity(update.getCity());
        institution.setType(update.getType());
        institution.setDescription(update.getDescription());
        institution.setAddress(update.getAddress());
        institution.setPhone(update.getPhone());
        institution.setEmail(update.getEmail());
        institution.setWebsiteUrl(update.getWebsiteUrl());
        institution.setLogoUrl(update.getLogoUrl());
        institution.setLatitude(update.getLatitude());
        institution.setLongitude(update.getLongitude());

        // Cover information is managed separately.
        // Updating institution details will not erase its cover.

        return institutionRepository.save(institution);
    }

    // Update cover for the authenticated institution admin
    public Institution updateInstitutionCover(
            Long institutionId,
            Institution coverData,
            Authentication authentication) {

        if (authentication == null
                || !authentication.isAuthenticated()) {

            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Login required");
        }

        AdminAccount admin = adminAccountRepository
                .findByEmail(authentication.getName())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "Admin not found"));

        if (admin.getRole() != AdminRole.INSTITUTION_ADMIN) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Institution admin access required");
        }

        if (admin.getInstitution() == null
                || !admin.getInstitution().getId()
                        .equals(institutionId)) {

            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "You cannot modify another institution");
        }

        if (coverData == null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Cover data is required");
        }

        if (coverData.getCoverTitle() != null
                && coverData.getCoverTitle().length() > 255) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Cover title is too long");
        }

        if (coverData.getCoverDescription() != null
                && coverData.getCoverDescription().length() > 2000) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Cover description is too long");
        }

        if (coverData.getCoverImageUrl() != null
                && coverData.getCoverImageUrl().length() > 2048) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Cover image URL is too long");
        }

        Institution institution = getInstitutionById(institutionId);

        institution.setCoverTitle(coverData.getCoverTitle());
        institution.setCoverDescription(coverData.getCoverDescription());
        institution.setCoverImageUrl(coverData.getCoverImageUrl());

        return institutionRepository.save(institution);
    }

    public void deleteInstitution(Long id) {

        Institution institution = getInstitutionById(id);

        if (adminAccountRepository.existsByInstitutionId(id)
                || announcementRepository.existsByInstitutionId(id)
                || eventRepository.existsByInstitutionId(id)) {

            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Delete the institution admin, announcements and events first");
        }

        institutionRepository.delete(institution);
    }

    private void validate(Institution institution) {

        if (institution == null
                || institution.getName() == null
                || institution.getName().isBlank()) {

            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Institution name is required");
        }
    }
    }
