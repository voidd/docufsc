/* Formatted on 22/10/2013 9:44:33 (QP5 v5.252.13127.32867) */
SELECT DISTINCT
          'scp /app/documentum/data/REPO/storage'
       || '/'
       || LPAD (SUBSTR (sys_s.r_object_id, 3, 6), 8, 0)
       || LOWER (
             REGEXP_REPLACE (
                SUBSTR (
                   TO_CHAR (
                      CASE
                         WHEN cs.data_ticket < 0
                         THEN
                            POWER (16, 16) + cs.data_ticket
                         ELSE
                            cs.data_ticket
                      END,
                      'XXXXXXXXXXXXXXXX'),
                   10,
                   8),
                '(\w\w)',
                '/\1'))
       || CASE
             WHEN dm_format.dos_extension <> ' '
             THEN
                '.' || dm_format.dos_extension
             ELSE
                ''
          END
       || ' dmadmin@documentumhost:/app/documentum/data/REPO/storage'
       || '/'
       || LPAD (SUBSTR (sys_s.r_object_id, 3, 6), 8, 0)
       || LOWER (
             REGEXP_REPLACE (
                SUBSTR (
                   TO_CHAR (
                      CASE
                         WHEN cs.data_ticket < 0
                         THEN
                            POWER (16, 16) + cs.data_ticket
                         ELSE
                            cs.data_ticket
                      END,
                      'XXXXXXXXXXXXXXXX'),
                   10,
                   8),
                '(\w\w)',
                '/\1'))
       || CASE
             WHEN dm_format.dos_extension <> ' '
             THEN
                '.' || dm_format.dos_extension
             ELSE
                ''
          END
          AS FILES_NAME
  FROM dm_sysobject_sp sys_s,
       dmr_content_sp cs,
       dmr_content_rp cr,
       dm_format_sp dm_format
 WHERE     cs.r_object_id = cr.r_object_id
       AND cr.parent_id = sys_s.r_object_id
       AND dm_format.r_object_id = cs.format
       AND dm_format.r_object_id IN (SELECT r_object_id
                                       FROM dm_format_sp
                                      WHERE dos_extension NOT IN ('pdf',
                                                                  'txt',
                                                                  'gif',
                                                                  'jpeg',
                                                                  'docx'))
       AND sys_s.r_object_id IN (SELECT ss.r_object_id
                                   FROM dm_sysobject_sp ss,
                                        dm_sysobject_rp sr
                                  WHERE     ss.r_object_id = sr.r_object_id
                                        AND ss.r_content_size > 0
                                        AND sr.i_folder_id IN (SELECT r_object_id
                                                                 FROM dm_folder_sp
                                                                WHERE i_cabinet_id IN (SELECT r_object_id
                                                                                         FROM dm_folder_r
                                                                                        WHERE r_folder_path IN ('/Templates',
                                                                                                                '/System',
                                                                                                                '/Resources'))));