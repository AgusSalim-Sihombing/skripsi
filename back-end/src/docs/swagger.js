const swaggerJSDoc = require("swagger-jsdoc");
require("dotenv").config();
const port = process.env.PORT || 3001;

const options = {
    definition: {
        openapi: "3.0.0",
        info: {
            title: "API SIGAP",
            version: "1.0.0",
            description: "Dokumentasi API untuk aplikasi SIGAP",
        },
        servers: [
            {
                url: `http://localhost:${port}/api`,
                description: "Local server",
            },
            {
                url: "https://domainkamu.com/api",
                description: "Production server",
            },
        ],
        components: {
            securitySchemes: {
                bearerAuth: {
                    type: "http",
                    scheme: "bearer",
                    bearerFormat: "JWT",
                },
            },
            schemas: {
                LoginRequest: {
                    type: "object",
                    required: ["username", "password"],
                    properties: {
                        username: {
                            type: "string",
                            example: "agus123",
                        },
                        password: {
                            type: "string",
                            example: "12345678",
                        },
                    },
                },
                LoginResponse: {
                    type: "object",
                    properties: {
                        message: {
                            type: "string",
                            example: "Login berhasil",
                        },
                        token: {
                            type: "string",
                            example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                        },
                        user: {
                            type: "object",
                            properties: {
                                id: { type: "integer", example: 1 },
                                username: { type: "string", example: "agus123" },
                                role: { type: "string", example: "admin" },
                            },
                        },
                    },
                },
            },

        },
    },

    tags: [
        {
            name: 'Roles',
        },
        {
            name: 'Users',
        },
    ],
    apis: [
        "./src/routes/*.js",
        "./src/routes/**/*.js",
    ],

};

const swaggerSpec = swaggerJSDoc(options);

module.exports = swaggerSpec;