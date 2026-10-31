
package com.institutionplatform.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "institutions")
public class Institution {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	private String name;

	// Institution cover
	@Column(length = 255)
	private String coverTitle;

	@Column(length = 2000)
	private String coverDescription;

	@Column(length = 2048)
	private String coverImageUrl;

	@Column(name = "city")
	private String city;

	private String type;

	@Column(length = 2000)
	private String description;

	private String address;

	private String phone;

	private String email;

	private String websiteUrl;

	private String logoUrl;

	private Double latitude;

	private Double longitude;

	// Constructors

	public Institution() {
	}

	public Institution(String name, String city) {
		this.name = name;
		this.city = city;
	}

	// Getters

	public Long getId() {
		return id;
	}

	public String getName() {
		return name;
	}

	public String getCoverTitle() {
		return coverTitle;
	}

	public String getCoverDescription() {
		return coverDescription;
	}

	public String getCoverImageUrl() {
		return coverImageUrl;
	}

	public String getCity() {
		return city;
	}

	public String getType() {
		return type;
	}

	public String getDescription() {
		return description;
	}

	public String getAddress() {
		return address;
	}

	public String getPhone() {
		return phone;
	}

	public String getEmail() {
		return email;
	}

	public String getWebsiteUrl() {
		return websiteUrl;
	}

	public String getLogoUrl() {
		return logoUrl;
	}

	public Double getLatitude() {
		return latitude;
	}

	public Double getLongitude() {
		return longitude;
	}

	// Setters

	public void setName(String name) {
		this.name = name;
	}

	public void setCoverTitle(String coverTitle) {
		this.coverTitle = coverTitle;
	}

	public void setCoverDescription(String coverDescription) {
		this.coverDescription = coverDescription;
	}

	public void setCoverImageUrl(String coverImageUrl) {
		this.coverImageUrl = coverImageUrl;
	}

	public void setCity(String city) {
		this.city = city;
	}

	public void setType(String type) {
		this.type = type;
	}

	public void setDescription(String description) {
		this.description = description;
	}

	public void setAddress(String address) {
		this.address = address;
	}

	public void setPhone(String phone) {
		this.phone = phone;
	}

	public void setEmail(String email) {
		this.email = email;
	}

	public void setWebsiteUrl(String websiteUrl) {
		this.websiteUrl = websiteUrl;
	}

	public void setLogoUrl(String logoUrl) {
		this.logoUrl = logoUrl;
	}

	public void setLatitude(Double latitude) {
		this.latitude = latitude;
	}

	public void setLongitude(Double longitude) {
		this.longitude = longitude;
	}
}
