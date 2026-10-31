
package com.institutionplatform.model;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;

@Entity
@Table(name = "institution_events")
public class InstitutionEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;

    @Column(length = 2000)
    private String description;

    private String location;

    // Event image URL
    @Column(length = 2048)
    private String imageUrl;

    private LocalDateTime startAt;

    private LocalDateTime endAt;

    private LocalDateTime createdAt;

    @ManyToOne
    @JoinColumn(name = "institution_id")
    private Institution institution;

    @ManyToOne
    @JoinColumn(name = "created_by")
    private AdminAccount createdBy;

    public InstitutionEvent() {
    }

    public InstitutionEvent(
            String title,
            String description,
            String location,
            LocalDateTime startAt,
            LocalDateTime endAt,
            Institution institution,
            AdminAccount createdBy) {

        this.title = title;
        this.description = description;
        this.location = location;
        this.startAt = startAt;
        this.endAt = endAt;
        this.institution = institution;
        this.createdBy = createdBy;
        this.createdAt = LocalDateTime.now();
    }

    @Transient
    public EventStatus getStatus() {
        LocalDateTime now = LocalDateTime.now();

        if (now.isBefore(startAt)) {
            return EventStatus.UPCOMING;
        }

        if (now.isAfter(endAt)) {
            return EventStatus.ENDED;
        }

        return EventStatus.ONGOING;
    }

    // Getters

    public Long getId() {
        return id;
    }

    public String getTitle() {
        return title;
    }

    public String getDescription() {
        return description;
    }

    public String getLocation() {
        return location;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public LocalDateTime getStartAt() {
        return startAt;
    }

    public LocalDateTime getEndAt() {
        return endAt;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public Institution getInstitution() {
        return institution;
    }

    public AdminAccount getCreatedBy() {
        return createdBy;
    }

    // Setters

    public void setTitle(String title) {
        this.title = title;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public void setStartAt(LocalDateTime startAt) {
        this.startAt = startAt;
    }

    public void setEndAt(LocalDateTime endAt) {
        this.endAt = endAt;
    }
}
