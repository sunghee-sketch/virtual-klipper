describe('Dashboard', () => {
    it('opens the page correctly', function () {
        cy.visit('/')
        cy.wait(2000)

        // 로그인 페이지로 리다이렉트되었는지 확인
        cy.url().should('include', '/login.html')

        // 로그인 페이지 요소 확인
        cy.contains('ALHS')
        cy.get('input[name="username"]').should('exist')
        cy.get('input[name="password"]').should('exist')
        cy.get('button[type="submit"]').should('exist')
    })
})
