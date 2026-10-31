package com.institutionplatform.model;

import java.time.LocalDateTime;

import jakarta.persistence.Entity;
import jakarta.persistence.Column;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;

@Entity
@Table(name = "announcements")
public class Announcement {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;

    private String content;

    private String imageUrl;

    private LocalDateTime createdAt;

    private LocalDateTime startAt;

    private LocalDateTime endAt;
    @Column(
    	    name = "show_on_display_screen",
    	    nullable = false,
    	    columnDefinition = "boolean default false")
    	private boolean showOnDisplayScreen;
    
    @ManyToOne
    @JoinColumn(name = "institution_id")
    private Institution institution;

    @ManyToOne
    @JoinColumn(name = "created_by")
    private AdminAccount createdBy;

    public Announcement() {
    }

    public Announcement(
            String title,
            String content,
            String imageUrl,
            LocalDateTime startAt,
            LocalDateTime endAt,
            boolean showOnDisplayScreen,
            Institution institution,
            AdminAccount createdBy) {

        this.title = title;
        this.content = content;
        this.imageUrl = imageUrl;
        this.startAt = startAt;
        this.endAt = endAt;
        this.showOnDisplayScreen = showOnDisplayScreen;
        this.institution = institution;
        this.createdBy = createdBy;
        this.createdAt = LocalDateTime.now();
    }

    @Transient
    public AnnouncementStatus getStatus() {

        LocalDateTime now = LocalDateTime.now();

        if (now.isBefore(startAt)) {
            return AnnouncementStatus.UPCOMING;
        }

        if (now.isAfter(endAt)) {
            return AnnouncementStatus.EXPIRED;
        }

        return AnnouncementStatus.ACTIVE;
    }

    public Long getId() {
        return id;
    }

    public String getTitle() {
        return title;
    }

    public String getContent() {
        return content;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public LocalDateTime getStartAt() {
        return startAt;
    }

    public LocalDateTime getEndAt() {
        return endAt;
    }

    public boolean isShowOnDisplayScreen() {
        return showOnDisplayScreen;
    }

    public Institution getInstitution() {
        return institution;
    }

    public AdminAccount getCreatedBy() {
        return createdBy;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public void setContent(String content) {
        this.content = content;
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

    public void setShowOnDisplayScreen(boolean showOnDisplayScreen) {
        this.showOnDisplayScreen = showOnDisplayScreen;
    }
}
