const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const {defineSecret} = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const OpenAI = require("openai");

setGlobalOptions({
  maxInstances: 10,
});

const openaiApiKey = defineSecret("OPENAI_API_KEY");

exports.extractExcavatorMaintenance = onRequest(
    {
      secrets: [openaiApiKey],
      cors: true,
    },
    async (req, res) => {
      try {
        if (req.method !== "POST") {
          return res.status(405).json({
            success: false,
            message: "Only POST requests are allowed.",
          });
        }

        const {imageBase64, mimeType} = req.body;

        if (!imageBase64) {
          return res.status(400).json({
            success: false,
            message: "imageBase64 is required.",
          });
        }

        const client = new OpenAI({
          apiKey: openaiApiKey.value(),
        });

        const response = await client.responses.create({
          model: "gpt-5.4-mini",
          input: [
            {
              role: "user",
              content: [
                {
                  type: "input_text",
                  text: `
You are an OCR and data extraction assistant for a Stone Crusher ERP.

The uploaded image is a handwritten Excavator Maintenance sheet.

Extract the information based on meaning and context.

IMPORTANT RULES:

1. Do NOT assume that fields are written in a fixed order.
2. Identify each value based on its meaning and surrounding context.
3. Do NOT invent missing information.
4. If a value is unclear or not present, return null.
5. Do NOT calculate derived values.
6. Preserve handwritten remarks as accurately as possible.
7. Registration number may look like:
   TN 25 BB 9860
8. Shift should normally be Day or Night.
9. Diesel filled should be represented as a number of liters.
10. Diesel rate should be the price per liter.
11. Teeth set changed should be true or false when clearly identifiable.
12. Return only the requested structured data.

Field definitions:

registration_number:
Excavator registration / vehicle registration number.

operator_name:
Name of the excavator operator.

shift:
Work shift such as Day or Night.

starting_hour:
Excavator hour-meter reading at the beginning of work.

closing_hour:
Excavator hour-meter reading at the end of work.

bucket_working_hour:
Hours spent working with the bucket.

breaker_working_hour:
Hours spent working with the breaker.

number_of_loads:
Number of loads handled.

number_of_units:
Number of units.

diesel_filled:
Diesel quantity filled, in liters.

diesel_rate:
Diesel price per liter.

teeth_set_changed:
Whether the excavator teeth set was changed.

remarks:
Any additional handwritten remarks.

Return null when information is missing or uncertain.
                  `,
                },
                {
                  type: "input_image",
                  image_url:
`data:${mimeType || "image/jpeg"};base64,${imageBase64}`,
                  detail: "high",
                },
              ],
            },
          ],
          text: {
            format: {
              type: "json_schema",
              name: "excavator_maintenance",
              strict: true,
              schema: {
                type: "object",
                properties: {
                  registration_number: {
                    type: ["string", "null"],
                  },
                  operator_name: {
                    type: ["string", "null"],
                  },
                  shift: {
                    type: ["string", "null"],
                  },
                  starting_hour: {
                    type: ["number", "null"],
                  },
                  closing_hour: {
                    type: ["number", "null"],
                  },
                  bucket_working_hour: {
                    type: ["number", "null"],
                  },
                  breaker_working_hour: {
                    type: ["number", "null"],
                  },
                  number_of_loads: {
                    type: ["integer", "null"],
                  },
                  number_of_units: {
                    type: ["integer", "null"],
                  },
                  diesel_filled: {
                    type: ["number", "null"],
                  },
                  diesel_rate: {
                    type: ["number", "null"],
                  },
                  teeth_set_changed: {
                    type: ["boolean", "null"],
                  },
                  remarks: {
                    type: ["string", "null"],
                  },
                },
                required: [
                  "registration_number",
                  "operator_name",
                  "shift",
                  "starting_hour",
                  "closing_hour",
                  "bucket_working_hour",
                  "breaker_working_hour",
                  "number_of_loads",
                  "number_of_units",
                  "diesel_filled",
                  "diesel_rate",
                  "teeth_set_changed",
                  "remarks",
                ],
                additionalProperties: false,
              },
            },
          },
        });

        const extractedData = JSON.parse(response.output_text);

        logger.info("Excavator maintenance extracted successfully.");

        return res.status(200).json({
          success: true,
          data: extractedData,
        });
      } catch (error) {
        logger.error("OCR extraction failed.", error);

        return res.status(500).json({
          success: false,
          message: "Failed to extract maintenance data.",
          error: error.message,
        });
      }
    },


);
exports.extractExcavatorService = onRequest(
    {
      secrets: [openaiApiKey],
      cors: true,
    },
    async (req, res) => {
      try {
        if (req.method !== "POST") {
          return res.status(405).json({
            success: false,
            message: "Only POST requests are allowed.",
          });
        }

        const {imageBase64, mimeType} = req.body;

        if (!imageBase64) {
          return res.status(400).json({
            success: false,
            message: "imageBase64 is required.",
          });
        }

        const client = new OpenAI({
          apiKey: openaiApiKey.value(),
        });

        const response = await client.responses.create({
          model: "gpt-5.4-mini",
          input: [
            {
              role: "user",
              content: [
                {
                  type: "input_text",
                  text: `
You are an OCR and data extraction assistant for a Stone Crusher ERP.

The uploaded image is a handwritten Excavator Service sheet.

Extract the information based on meaning, context, handwriting, labels,
table structure, and surrounding values.

IMPORTANT RULES:

1. Do NOT assume that fields are written in a fixed order.
2. Understand the meaning of each value from the surrounding context.
3. Do NOT invent missing information.
4. If a value is unclear or not present, return null.
5. Preserve handwritten text as accurately as possible.
6. Extract ALL service items visible in the image.
7. Each service item may contain:
   - spare part name
   - quantity
   - cost per unit
   - item-specific remark
8. Do NOT calculate the grand total.
9. Do NOT create or invent spare parts.
10. The spare part name should be extracted as written, but normalized
    only enough to remove obvious handwriting punctuation such as:
    "A.C. Filter" -> "A.C Filter"
11. The final paragraph or general note that applies to the complete
    service should be returned as service_remarks.
12. A remark written next to a particular spare item belongs to that
    item's item_remark, not service_remarks.
13. Return null for missing or uncertain scalar values.
14. Return an empty array when no service items are identifiable.
15. Return only the requested structured data.

FIELD DEFINITIONS:

registration_number:
Excavator registration number.

service_date:
Date on which the excavator service was performed.
Return in YYYY-MM-DD format when the date can be clearly identified.

current_hour_meter:
Excavator hour-meter reading at the time of service.

service_items:
List of spare parts/items replaced or serviced.

spare_part:
Name of the spare part or service item.

quantity:
Quantity of the spare part used or replaced.

cost:
Cost per unit of the spare part.
Do NOT multiply quantity by cost.

item_remark:
Remark specifically associated with that spare part/item.

service_remarks:
General remark or explanation applicable to the overall service.

IMPORTANT INTERPRETATION EXAMPLE:

If the sheet contains something like:

A.C Filter    1    100    due to dust

then extract:

spare_part = "A.C Filter"
quantity = 1
cost = 100
item_remark = "due to dust"

If another item contains:

Gear Box    1    500    Unable to put proper gear

then "Unable to put proper gear" belongs to item_remark.

If a paragraph appears at the bottom describing the overall
service reason, that belongs to service_remarks.

Again, do NOT calculate totals and do NOT invent values.
                  `,
                },
                {
                  type: "input_image",
                  image_url:
`data:${mimeType || "image/jpeg"};base64,${imageBase64}`,
                  detail: "high",
                },
              ],
            },
          ],
          text: {
            format: {
              type: "json_schema",
              name: "excavator_service",
              strict: true,
              schema: {
                type: "object",
                properties: {
                  registration_number: {
                    type: ["string", "null"],
                  },
                  service_date: {
                    type: ["string", "null"],
                  },
                  current_hour_meter: {
                    type: ["number", "null"],
                  },
                  service_items: {
                    type: "array",
                    items: {
                      type: "object",
                      properties: {
                        spare_part: {
                          type: ["string", "null"],
                        },
                        quantity: {
                          type: ["number", "null"],
                        },
                        cost: {
                          type: ["number", "null"],
                        },
                        item_remark: {
                          type: ["string", "null"],
                        },
                      },
                      required: [
                        "spare_part",
                        "quantity",
                        "cost",
                        "item_remark",
                      ],
                      additionalProperties: false,
                    },
                  },
                  service_remarks: {
                    type: ["string", "null"],
                  },
                },
                required: [
                  "registration_number",
                  "service_date",
                  "current_hour_meter",
                  "service_items",
                  "service_remarks",
                ],
                additionalProperties: false,
              },
            },
          },
        });

        const extractedData = JSON.parse(response.output_text);

        logger.info("Excavator service extracted successfully.");

        return res.status(200).json({
          success: true,
          data: extractedData,
        });
      } catch (error) {
        logger.error("Excavator service OCR extraction failed.", error);

        return res.status(500).json({
          success: false,
          message: "Failed to extract service data.",
          error: error.message,
        });
      }
    },
);
