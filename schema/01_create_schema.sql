-- Create a dedicated schema for all Synthea data
CREATE SCHEMA IF NOT EXISTS synthea;

SET search_path TO synthea, public;
