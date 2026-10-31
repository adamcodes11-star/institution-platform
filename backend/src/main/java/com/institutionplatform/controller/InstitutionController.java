
package com.institutionplatform.controller;

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
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.institutionplatform.model.Institution;
import com.institutionplatform.service.InstitutionService;
@RestController
@RequestMapping("/api/institutions")
public class InstitutionController {

    private final InstitutionService institutionService;

    public InstitutionController(InstitutionService institutionService) {
        this.institutionService = institutionService;
    }

    // Public: get all institutions
    @GetMapping
    public List<Institution> getAllInstitutions() {
        return institutionService.getAllInstitutions();
    }

    // Public: get institution by ID
    @GetMapping("/{id}")
    public Institution getInstitutionById(@PathVariable Long id) {
        return institutionService.getInstitutionById(id);
    }

    // Public: search institutions
    @GetMapping("/search")
    public List<Institution> searchInstitutions(
            @RequestParam(required = false) String name,
            @RequestParam(required = false) String city,
            @RequestParam(required = false) String type) {

        return institutionService.searchInstitutions(name, city, type);
    }

    // Super Admin: add institution
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    @PostMapping
    public Institution addInstitution(
            @RequestBody Institution institution) {

        return institutionService.addInstitution(institution);
    }

    // Super Admin: update institution
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    @PutMapping("/{id}")
    public Institution updateInstitution(
            @PathVariable Long id,
            @RequestBody Institution institution) {

        return institutionService.updateInstitution(id, institution);
    }

    // Institution Admin: update own institution cover
    @PreAuthorize("hasRole('INSTITUTION_ADMIN')")
    @PutMapping("/{id}/cover")
    public Institution updateInstitutionCover(
            @PathVariable Long id,
            @RequestBody Institution coverData,
            Authentication authentication) {

        return institutionService.updateInstitutionCover(
                id,
                coverData,
                authentication);
    }

    // Super Admin: delete institution
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    @DeleteMapping("/{id}")
    public void deleteInstitution(@PathVariable Long id) {
        institutionService.deleteInstitution(id);
    }
}
