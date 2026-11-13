# =============================================================================
# Dockerfile — Odoo 19.0 + OCA Management System addons
# =============================================================================
# Builds a production-ready container image for the OCA management-system
# addon repository on top of the official Odoo 19.0 image.
#
# Build:
#   docker build -t mgmtsystem-odoo:19.0 .
#
# Run (requires a PostgreSQL container — see docker-compose.yml):
#   docker compose up -d
#
# Then open: http://localhost:8069
# =============================================================================

FROM odoo:19.0

LABEL maintainer="OCA Management System <https://github.com/OCA/management-system>"
LABEL org.opencontainers.image.title="OCA Management System (Odoo 19.0)"
LABEL org.opencontainers.image.description="Odoo 19.0 with OCA management-system addons (ISO 9001, ISO 14001, ISO 45001, ISO 27001, etc.)"
LABEL org.opencontainers.image.source="https://github.com/OCA/management-system"
LABEL org.opencontainers.image.licenses="AGPL-3.0"

# ---------------------------------------------------------------------------
# Switch to root for system-level operations
# ---------------------------------------------------------------------------
USER root

# ---------------------------------------------------------------------------
# Install gettext for envsubst (used by entrypoint-wrapper.sh)
# ---------------------------------------------------------------------------
RUN apt-get update \
    && apt-get install -y --no-install-recommends gettext-base postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Copy the addon modules into Odoo's extra addons path.
# Only module directories (those containing __manifest__.py) are copied.
# ---------------------------------------------------------------------------
RUN mkdir -p /mnt/extra-addons

COPY --chown=odoo:odoo \
    mgmtsystem/ \
    mgmtsystem_action/ \
    mgmtsystem_audit/ \
    mgmtsystem_environment/ \
    mgmtsystem_hazard/ \
    mgmtsystem_hazard_risk/ \
    mgmtsystem_health_safety/ \
    mgmtsystem_information_security/ \
    mgmtsystem_info_security_manual/ \
    mgmtsystem_kpi/ \
    mgmtsystem_manual/ \
    mgmtsystem_nonconformity/ \
    mgmtsystem_nonconformity_hr/ \
    mgmtsystem_nonconformity_repair/ \
    mgmtsystem_partner/ \
    mgmtsystem_quality/ \
    mgmtsystem_review/ \
    mgmtsystem_risk/ \
    mgmtsystem_security_event/ \
    mgmtsystem_survey/ \
    document_page_environment_manual/ \
    document_page_environmental_aspect/ \
    document_page_health_safety_manual/ \
    document_page_procedure/ \
    document_page_quality_manual/ \
    document_page_work_instruction/ \
    /mnt/extra-addons/

# ---------------------------------------------------------------------------
# Copy the custom Odoo configuration file and entrypoint wrapper
# ---------------------------------------------------------------------------
COPY --chown=odoo:odoo docker/odoo.conf /etc/odoo/odoo.conf
COPY --chown=root:root docker/entrypoint-wrapper.sh /entrypoint-wrapper.sh
RUN chmod +x /entrypoint-wrapper.sh

# ---------------------------------------------------------------------------
# Switch back to the odoo user
# ---------------------------------------------------------------------------
USER odoo

# ---------------------------------------------------------------------------
# Use the wrapper as entrypoint (it substitutes env vars, waits for DB,
# then hands off to the official Odoo entrypoint)
# ---------------------------------------------------------------------------
ENTRYPOINT ["/entrypoint-wrapper.sh"]

CMD ["odoo"]

# ---------------------------------------------------------------------------
# Expose Odoo's default ports:
#   8069 — longpolling / HTTP
#   8072 — livechat (websocket)
# ---------------------------------------------------------------------------
EXPOSE 8069 8072
